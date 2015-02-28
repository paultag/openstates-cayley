(import json
        [collections [Counter]]
        [pyley [CayleyClient GraphObject]])


(defn ? [server body]
  (. (.Send server body) result ["result"]))


(defmacro --> [&rest args] `(.Out ~@args))
(defmacro <-- [&rest args] `(.In ~@args))
(defmacro g-> [&rest args] `(-> g ~@args))


(defn ->t<- [el tag name back]
  "Out, tag and return, to fetch additional attributes"
  (-> el
    (--> tag)
    (.Tag name)
    (.Back back)))


(defmacro defn/g [name signature &rest body]
  `(defn ~name [~@signature]
     (import [pyley [GraphObject]])
     (setv g (GraphObject))  ; let is overkill here
      ~@body))


(defn/g get-legislators [server]
  (? server
    (g-> (.V)
      (.Tag "leg_id")
      ; get name and state
      (->t<- "/legislator/name" "name" "leg_id")
      (->t<- "/legislator/state" "state" "leg_id")
      .All)))


(defn generate-vector-count [data]
  (if (nil? data)
    []
    (let [[stream (map (fn [x] (get x "id")) data)]
          [count (Counter stream)]]
      (.most-common count))))


(defn/g sponsorship-vector [server leg]
  " Generate the vector of sponsorships "
  (let [[leg-id (get leg "id")]
        [sponsored ["/bill/sponsor/cosponsor" "/bill/sponsor/primary"]]
        [data (? server
                (g-> (.V leg-id)
                  (<-- sponsored)
                  (--> sponsored)
                  .All))]]
    (generate-vector-count data)))


(defn save-data [leg vector]
  (let [[path (.format "{}.json" (get leg "leg_id"))]]
    (assoc leg "cohorts" vector)
    (with [[fd (open path "w")]]
      (print (.format "Writing {}" path))
      (.dump json leg fd))))


(defn generate-sponsorship-vector [server leg]
  (save-data leg (sponsorship-vector server leg)))


(defn generate-sponsorship-vectors [server legs]
  (for [leg legs] (generate-sponsorship-vector server leg)))


(let [[client (CayleyClient "http://localhost:8888")]]
  (generate-sponsorship-vectors client (get-legislators client)))
