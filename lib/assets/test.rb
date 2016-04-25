Donorset.update_all(del: false)
dd = Donorset.last
p = Party.new({ name: "blah" , title: "blah1", description: "blah2" })
d = Donor.new({ first_name: "a", last_name: "b", give_date: Time.now, party_id: p._id, amount: 0, tin: 333 })
dd.donors << d
dd.save
