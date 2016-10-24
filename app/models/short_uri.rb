# Short class - Map class for url to short url
class ShortUri
  include Mongoid::Document
  include Mongoid::Timestamp

  TYPES = [:explore, :embed_static]
  OTHER_STATES = [:donation, :finance]

  field :sid, type: String # base58 string from nid
  field :nid, type: Integer # sequence id
  field :tp, type: Integer, default: 0 # type of uri explore=0|embed_static=1

  field :rid, type: String # related id in case explore md5 string from uri, for comparison ease

  field :pars, type: Hash, default: {}
  field :activated, type: Boolean, default: false

  field :other, type: Integer # currently saves if it is donation or finance

  scope :by_type, -> v { where("tp" => v) }

  # indexes
  index({ sid: 1 }, { unique: true })
  index({ rid: 1 }, { unique: true })
  index({ tp: 1 })

  def self.by_sid(sid, tp)
    tp = self.type_is(tp)
    return nil unless tp.present?
    shr = ShortUri.by_type(tp).limit(1).find_by({ sid: sid })
    shr.set(activated: true) if tp == 1 && !shr.activated
    shr.present? ? shr : nil
  end

  # def self.by_rid(pars, tp)
  #   return nil if pars.class != Hash || !pars.present?
  #   tp = self.type_is(tp)
  #   return nil unless tp.present?
  #   tmp = []
  #   pars.keys.sort.each{ |e|
  #     p = pars[e]
  #     p = p.class == "Array" ? p.sort : p
  #     tmp << "#{e}=#{p}"
  #   }
  #   uri_str = tmp.join("&")

  #   rid = Digest::MD5.hexdigest(uri_str)
  #   shr = ShortUri.by_type(tp).limit(1).find_by({ rid: rid })
  #   shr.present? ? shr : nil
  # end

  def self.explore_uri(pars)
    pars = pars.to_h
    return nil if pars.class != Hash || !pars.present?
    is_donation = pars[:filter] == "donation"
    tmp = []
    except = []
    if is_donation
      if pars[:period].present?
        pars[:period_mils] = pars[:period].map{ |m| (m.to_f * 1000).to_i }
        except = [:period, :amount]
      end
    end
    pars.keys.sort.each{ |e|
      p = pars[e]
      if is_donation
        next if e == :period_mils
        if e == :period
          p = pars[:period_mils]
          pars.delete(:period_mils)
        end
      end

      p = p.class == Array && except.index(e).nil? ? p.sort : [p]
      tmp << "#{e}=#{p.join(',')}"
    }
    rid = Digest::MD5.hexdigest(tmp.join("&"))
    # Rails.logger.fatal("************************")
    # Rails.logger.fatal("#{rid}")
    # Rails.logger.fatal("#{tmp.join("&")}")
    shr = ShortUri.by_type(0).limit(1).find_by({ rid: rid })
    sid = nil
    if shr.present?
      sid = shr.sid
    else
      nid = ShortUri.sequence_id_for("explore_id")
      sid = Base58.encode(nid)
      ShortUri.create({ sid: sid, nid: nid, rid: rid, pars: pars, tp: 0, other: is_donation ? 0 : 1 })
    end
    sid
  end

  def self.embed_static_uri(rid)
    exp = ShortUri.by_sid(rid, :explore) # ShortUri object of related explore row, so ready pars can be taken from it
    return nil unless exp.present? && exp.pars.has_key?("filter") && ["finance", "donation"].index(exp.pars["filter"]).present?

    # Rails.logger.fatal("#{rid} #{exp}")
    is_donation = exp.pars[:filter] == "donation"
    pars = is_donation ? Donor.explore(exp.pars, "co", true) : Dataset.explore(exp.pars, "co", true)

    nid = ShortUri.sequence_id_for("embed_static_id")
    sid = Base58.encode(nid)
    ShortUri.create({ sid: sid, nid: nid, rid: rid, pars: pars, tp: 1, other: is_donation ? 0 : 1 })

    sid
  end
  private
    def self.type_is(tp)
      TYPES.index(tp.to_sym)
    end
    def self.sequence_id_for(id)
      db = Mongoid.default_client
      res = db.command({
        findAndModify: "sequence",
        query: { _id: id },
        update: { "$inc": { seq: 1 } },
        new: true
      })
      res.documents[0][:value][:seq].to_i
    end
end
