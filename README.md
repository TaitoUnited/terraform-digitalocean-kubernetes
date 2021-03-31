# DigitalOcean Kubernetes

Example usage:

```
provider "digitalocean" {
  token        = var.do_token
}

module "kubernetes" {
  source              = "TaitoUnited/kubernetes/digitalocean"
  version             = "1.0.0"

  email                      = "devops@mydomain.com"

  # Network
  private_network_id         = module.network.private_network_id

  # Permissions
  permissions                = yamldecode(
    file("${path.root}/../infra.yaml")
  )["permissions"]

  # Kubernetes
  kubernetes                 = yamldecode(
    file("${path.root}/../infra.yaml")
  )["kubernetes"]

  # Container registry
  registry_name                   = "my-infrastructure"
  registry_subscription_tier_slug = "starter"

  # Helm infrastructure apps
  helm_enabled               = false  # Should be false on the first run, then true
  generate_ingress_dhparam   = false
  use_kubernetes_as_db_proxy = true
  postgresql_cluster_names   = [ "my-postgresql-1" ]
  mysql_cluster_names        = [ "my-mysql-1" ]
}
```

Example YAML:

```
# Permissions
permissions:

  # Cluster-wide permissions
  clusterRoles:
    - name: taito-iam-admin
      subjects: [ "ADMINS_GROUP_ID" ]
    - name: taito-status-viewer
      subjects: [ "DEVELOPERS_GROUP_ID" ]

  # Namespace specific permissions
  namespaces:
    - name: common
      clusterRoles:
        - name: taito-secret-viewer
          subjects:
            - DEVELOPERS_GROUP_ID
            - CICD_TESTER_USER_ID
    - name: db-proxy
      clusterRoles:
        - name: taito-pod-portforwarder
          subjects:
            - DEVELOPERS_GROUP_ID
            - CICD_TESTER_USER_ID
    - name: my-namespace
      clusterRoles:
        - name: taito-developer
          subjects:
            - SOME_USER_ID
            - ANOTHER_USER_ID
    - name: another-namespace
      clusterRoles:
        - name: taito-developer
          subjects:
            - SOME_USER_ID
            - ANOTHER_USER_ID            

kubernetes:
  name: zone1-common-kube1
  region: ams2
  version: 1.18.
  autoUpgrade: true
  surgeUpgrade: false

  nodePools:
    - name: pool-1
      size: s-2vcpu-2gb
      minNodeCount: 1
      maxNodeCount: 1

  # Ingress controllers
  ingressNginxControllers:
    - name: ingress-nginx
      class: nginx
      replicas: 3
      metricsEnabled: true
      # MaxMind license key for GeoIP2: https://support.maxmind.com/account-faq/license-keys/how-do-i-generate-a-license-key/
      maxmindLicenseKey:
      # Map TCP/UDP connections to services
      tcpServices:
        3000: my-namespace/my-tcp-service:9000
      udpServices:
        3001: my-namespace/my-udp-service:9001
      # See https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/
      configMap:
        # Hardening
        # See https://kubernetes.github.io/ingress-nginx/deploy/hardening-guide/
        keep-alive: 10
        custom-http-errors: 403,404,503,500
        server-snippet: >
          location ~ /\.(?!well-known).* {
            deny all;
            access_log off;
            log_not_found off;
            return 404;
          }
        hide-headers: Server,X-Powered-By
        ssl-ciphers: EECDH+AESGCM:EDH+AESGCM
        enable-ocsp: true
        hsts-preload: true
        ssl-session-tickets: false
        client-header-timeout: 10
        client-body-timeout: 10
        large-client-header-buffers: 2 1k
        client-body-buffer-size: 1k
        proxy-body-size: 1k
        # Firewall and access control
        enable-modsecurity: true
        enable-owasp-modsecurity-crs: true
        use-geoip: false
        use-geoip2: true
        enable-real-ip: false
        whitelist-source-range: ""
        block-cidrs: ""
        block-user-agents: ""
        block-referers: ""

  # Certificate managers
  certManager:
    enabled: true

  # TIP: You can install more infrastructure apps on your Kubernetes with:
  # https://github.com/TaitoUnited/infra-apps-template
```

YAML attributes:

- See variables.tf for all the supported YAML attributes.
- See [kubernetes_cluster](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster) for attribute descriptions.

Combine with the following modules to get a complete infrastructure defined by YAML:

- [DNS](https://registry.terraform.io/modules/TaitoUnited/dns/digitalocean)
- [Network](https://registry.terraform.io/modules/TaitoUnited/network/digitalocean)
- [Compute](https://registry.terraform.io/modules/TaitoUnited/compute/digitalocean)
- [Kubernetes](https://registry.terraform.io/modules/TaitoUnited/kubernetes/digitalocean)
- [Databases](https://registry.terraform.io/modules/TaitoUnited/databases/digitalocean)
- [Storage](https://registry.terraform.io/modules/TaitoUnited/storage/digitalocean)
- [PostgreSQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/postgresql)
- [MySQL privileges](https://registry.terraform.io/modules/TaitoUnited/privileges/mysql)

TIP: Similar modules are also available for AWS, Azure, and Google Cloud. All modules are used by [infrastructure templates](https://taitounited.github.io/taito-cli/templates#infrastructure-templates) of [Taito CLI](https://taitounited.github.io/taito-cli/). See also [DigitalOcean project resources](https://registry.terraform.io/modules/TaitoUnited/project-resources/digitalocean), [Full Stack Helm Chart](https://github.com/TaitoUnited/taito-charts/blob/master/full-stack), and [full-stack-template](https://github.com/TaitoUnited/full-stack-template).

Contributions are welcome!
