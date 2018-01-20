#!/usr/bin/env boot

; Define deps to pull in dependencies dynamically
(defn deps [new-deps]
  (merge-env! :dependencies new-deps))

(deps '[[org.clojure/clojure "1.9.0"]
        [lein-cprint "1.2.0"]])

(import 'java.util.Base64)
;; (require) ;'[clojure.java.shell :refer [sh]]

         ;; '[leiningen.cprint :refer [cprint]])

;; (sh ) echo ${SERVICE_ACCOUNT} | base64 -d > service-account.json
;; RUN gcloud auth activate-service-account --key-file service-account.json

;; RUN gcloud config set compute/zone europe-west1-c
;; RUN gcloud config set project our-blue-dot
;; RUN gcloud container clusters get-credentials our-blue-dot

;; (cprint "LOLOLOL")

(defn decode [to-decode]
  (String. (.decode (Base64/getDecoder) to-decode)))


(def service-account (let [encoded (System/getenv "SERVICE_ACCOUNT")]
                        (if encoded
                          (decode encoded)
                          (do
                            (println "Error: No ENV SERVICE_ACCOUNT")
                            (System/exit 1)))))



(println service-account)

(System/exit 0)
