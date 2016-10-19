# Short class - Map class for url to short url
class ShortUri
  include Mongoid::Document

  field :sid, type: String # base58 string from nid
  field :nid, type: Integer # sequence id
  field :mid, type: String # md5 string from uri, for ease of comparing
  field :uri, type: String # raw uri
  field :pars, type: Hash, default: {}
  # indexes
  index({ sid: 1 }, { unique: true })
  index({ mid: 1 }, { unique: true })

  def self.by_sid(sid)
    shr = ShortUri.limit(1).find_by({ sid: sid })
    shr.present? ? shr : nil
  end

  def self.by_mid(pars)
    return nil if pars.class != Hash || !pars.present?

    tmp = []
    pars.keys.sort.each{ |e|
      p = pars[e]
      p = p.class == "Array" ? p.sort : p
      tmp << "#{e}=#{p}"
    }
    uri_str = tmp.join("&")

    mid = Digest::MD5.hexdigest(uri_str)
    shr = ShortUri.limit(1).find_by({ mid: mid })
    shr.present? ? shr : nil
  end

  def self.explore_uri(pars)
    pars = pars.to_h
    return nil if pars.class != Hash || !pars.present?

    tmp = []
    pars.keys.sort.each{ |e|
      p = pars[e]
      p = p.class == Array ? p.sort : p
      tmp << "#{e}=#{p}"
    }
    uri_str = tmp.join("&")
    mid = Digest::MD5.hexdigest(uri_str)
    shr = ShortUri.limit(1).find_by({ mid: mid })
    sid = nil
    if shr.present?
      sid = shr.sid
    else
      db = Mongoid.default_client
      res = db.command({
        findAndModify: "sequence",
        query: { _id: "explore_id" },
        update: { "$inc": { seq: 1 } },
        new: true
      })
      nid = res.documents[0][:value][:seq].to_i
      sid = Base58.encode(nid)
      ShortUri.create({ sid: sid, nid: nid, mid: mid, uri: uri_str, pars: pars })
    end
    Rails.logger.debug("----------------------------------------shorter----#{uri_str} #{sid} #{shr.present?}")
    sid
  end
end
