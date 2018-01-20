#!/usr/bin/env boot

; Define deps to pull in dependencies dynamically
(merge-env! '[[org.clojure/clojure "1.9.0"]])

(defn -main [& args]
  (info "A work in progress"))
