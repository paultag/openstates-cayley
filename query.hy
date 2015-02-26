(import [pyley [CayleyClient GraphObject]]
        [collections [Counter]])



(defmacro/g! query [client &rest path]
  "Query the server"

  `(let [[~g!g (GraphObject)]
         [~g!query (-> ~g!g ~@path)]
         [~g!response (.Send ~client ~g!query)]]
    (get (. ~g!response result) "result")))


(let [[c (CayleyClient "http://localhost:8888")]
      [edges (query c (.V "CAL000141")
                      (.In "/bill/sponsor/cosponsor")
                      (.Out "/bill/sponsor/cosponsor")
                      (.All))]
      [rank (Counter (map (fn [x] (get x "id")) edges))]]
    (print rank))
