LOCAL_PORT	:= 8080
REMOTE_PORT := 80

.PHONY: kafka-manager
kafka-manager:
	@lsof -i :$(LOCAL_PORT) | awk '/kubectl/{print $$2}' | tail -n +2 | xargs kill -9
	@kubectl port-forward `kubectl get po | awk '/(^kafka.*)manager(.*)/{print $$1;}'` $(LOCAL_PORT):$(REMOTE_PORT) &
	@open http://localhost:$(LOCAL_PORT)
