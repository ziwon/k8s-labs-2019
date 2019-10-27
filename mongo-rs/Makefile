MONGO_DB := admin
MONGO_USER := root
MONGO_PASS := root_topsecret

MONGO_SVC_USER := svc_awesome
MONGO_SVC_PASS := svc_topsecret
RS := 2

define CRLF


endef

# Initialize Mongo RS
define MONGO_RS_INIT
rs.initiate({
	_id: "rs0",
	protocolVersion: 1,
	members: [{
		_id: 0,
		host: "mongo-0.mongo.default.svc.cluster.local:27017"
	}, {
		_id: 1,
		host: "mongo-1.mongo.default.svc.cluster.local:27017"
	}, {
		_id: 2,
		host: "mongo-2.mongo.default.svc.cluster.local:27017"
	}]
});
endef

# Reinitialize Mongo RS
define MONGO_RS_CONF
rs.stepDown();
var cfg = rs.conf();
if (cfg.members[0]) { cfg.members[0].host="mongo-0.mongo.default.svc.cluster.local:27017"; }
if (cfg.members[1]) { cfg.members[1].host="mongo-1.mongo.default.svc.cluster.local:27017"; }
if (cfg.members[2]) { cfg.members[2].host="mongo-2.mongo.default.svc.cluster.local:27017"; }
rs.reconfig(cfg, {force : true});
endef

# Create root account
define MONGO_ROOT_USER
db = db.getSiblingDB("admin");
db.createUser({ user: "$(MONGO_USER)", pwd: "$(MONGO_PASS)", roles: [{ role: "root", db: "admin" }] });
endef

# Create service account
define MONGO_SVC_USER
db = db.getSiblingDB("admin");
db.createUser({ user: "$(MONGO_SVC_USER)", pwd: "$(MONGO_SVC_PASS)", roles: [{ role: "dbAdmin", db: "splash" }] });
endef

.PHONY: gen-key
gen-key:
	@echo -n $(openssl rand -base64 512) | base64

.PHONY: rsinit
rsinit:
	kubectl exec mongo-$(RS) -c mongo -- mongo --eval '$(subst $(CRLF), ,${MONGO_RS_INIT})'

.PHONY: reconf
reconf:
	kubectl exec mongo-$(RS) -c mongo -- mongo $(MONGO_DB) -u $(MONGO_USER) -p $(MONGO_PASS) --authenticationDatabase admin --eval '$(subst $(CRLF), ,${MONGO_RS_CONF})'

.PHONY: create-root-user
create-root-user:
	kubectl exec mongo-$(RS) -c mongo -c mongo -- mongo --eval '$(subst $(CRLF), ,${MONGO_ROOT_USER})'

.PHONY: create-svc-user
create-svc-user:
	kubectl exec mongo-$(RS) -c mongo -c mongo -- mongo --eval '$(subst $(CRLF), ,${MONGO_SVC_USER})'

.PHONY: primary
primary:
	for ((i = 0; i < 3; ++i)); do kubectl exec --namespace default mongo-$$i -- sh -c 'mongo --eval="printjson(rs.isMaster())"'; done

# ex) make status RS=1 (default: RS=2)
.PHONY: status
status:
	for ((i = 0; i < 3; ++i)); do kubectl exec mongo-$$i -c mongo -- mongo $(MONGO_DB) -u $(MONGO_USER) -p $(MONGO_PASS) --authenticationDatabase admin --eval="rs.status()"; done

# ex) make shell RS=1 (default: RS=2)
.PHONY: shell
shell:
	kubectl exec -it $$(kubectl get po | awk '/(.*)?mongo-$(RS)/{print $$1;}') -- mongo $(MONGO_DB) -u $(MONGO_USER) -p $(MONGO_PASS) --authenticationDatabase admin

# ex) make log RS=1 (default: RS=2)
.PHONY: logs
logs:
	kubectl logs -f $$(kubectl get po | awk '/(.*)?mongo-$(RS)/{print $$1;}')
