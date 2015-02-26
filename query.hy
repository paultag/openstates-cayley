(import [pyley [CayleyClient GraphObject]]
        [collections [Counter]])



(defmacro/g! query [client &rest path]
  "Query the server"

  `(let [[~g!g (GraphObject)]
         [~g!query (-> ~g!g ~@path)]
         [~g!response (.Send ~client ~g!query)]]
    (get (. ~g!response result) "result")))


(let [[leg "CAL000141"]
      [c (CayleyClient "http://localhost:8888")]
      [edges (query c (.V leg)
                      (.In ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
                      (.Out ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"])
                      (.All))]
      [rank (Counter (map (fn [x] (get x "id")) edges))]]

  (print (.format "Most often sponsors with {}" leg))
  (for [(, leg rank) (.most-common rank 20)]
    (print " " leg rank)))
