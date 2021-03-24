/**
 * Copyright 2021 Taito United
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "digitalocean_container_registry" "registry" {
  name                   = var.registry_name
  subscription_tier_slug = var.registry_subscription_tier_slug
}

resource "digitalocean_container_registry_docker_credentials" "registry" {
  registry_name = digitalocean_container_registry.registry.name
}

provider "kubernetes" {
  host             = digitalocean_kubernetes_cluster.kubernetes[0].endpoint
  token            = digitalocean_kubernetes_cluster.kubernetes[0].kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.kubernetes[0].kube_config[0].cluster_ca_certificate
  )
}

resource "kubernetes_secret" "dockerconfigjson" {
  metadata {
    name = "docker-cfg"
  }

  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.registry.docker_credentials
  }

  type = "kubernetes.io/dockerconfigjson"
}
