(import sys
        [cayley [fetcher]]
        [collections [Counter]])
(require cayley)


(defn most-common [els]
  (.most-common (Counter (map (fn [x] (get x "id")) els)) 20))


(defn print/ranked [ordering info]
  (let [[fmt "({state}) {name} - {id}"]]
    (for [(, leg value) ordering]
      (print value (apply fmt.format [] (get info leg))))))


(if (< (len sys.argv) 2)
  (do (print "Enter an arg, like CAL000141")
      (.exit sys 1)))


; e.g. CAL000141
(let [[leg (get sys.argv 1)]
      [Fetch (fetcher "leg_id")]]

  (cayley/connect "http://localhost:8888"
    (let [[g (GraphObject)]
          [cosponsors (query (-> g (.V leg)
              (.In ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
              (.Out ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
              (.All)))]
          [partners-in-crime (most-common cosponsors)]
          [m (query (-> (apply g.V (map first partners-in-crime))
                          (.Tag "leg_id")
                          (Fetch "name" "/legislator/name")
                          (Fetch "state" "/legislator/state")
                          (.All)))]
          [data (dict-comp (get x "id") x [x m])]]

    (print/ranked partners-in-crime data))))
