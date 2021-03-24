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

data "digitalocean_kubernetes_versions" "kubernetes" {
  version_prefix = local.kubernetes.version
}

resource "digitalocean_kubernetes_cluster" "kubernetes" {
  count          = local.kubernetes.name != "" ? 1 : 0

  name           = local.kubernetes.name
  region         = local.kubernetes.region
  auto_upgrade   = local.kubernetes.autoUpgrade
  surge_upgrade  = local.kubernetes.surgeUpgrade
  version        = data.digitalocean_kubernetes_versions.kubernetes.latest_version

  vpc_uuid       = var.private_network_id

  node_pool {
    name       = local.kubernetes.nodePools[0].name
    size       = local.kubernetes.nodePools[0].size
    auto_scale = local.kubernetes.nodePools[0].minNodeCount != local.kubernetes.nodePools[0].maxNodeCount
    node_count = local.kubernetes.nodePools[0].minNodeCount == local.kubernetes.nodePools[0].maxNodeCount ? local.kubernetes.nodePools[0].minNodeCount : null
    min_nodes  = local.kubernetes.nodePools[0].minNodeCount != local.kubernetes.nodePools[0].maxNodeCount ? local.kubernetes.nodePools[0].minNodeCount : null
    max_nodes  = local.kubernetes.nodePools[0].maxNodeCount != local.kubernetes.nodePools[0].maxNodeCount ? local.kubernetes.nodePools[0].maxNodeCount : null
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_kubernetes_node_pool" "bar" {
  for_each   = {for item in slice(local.kubernetes.nodePools, 1, length(local.kubernetes.nodePools)): item.name => item}

  cluster_id = digitalocean_kubernetes_cluster.kubernetes[0].id

  name       = each.value.name
  size       = each.value.size
  auto_scale = each.value.minNodeCount != each.value.maxNodeCount
  node_count = each.value.minNodeCount == each.value.maxNodeCount ? each.value.minNodeCount : null
  min_nodes  = each.value.minNodeCount != each.value.maxNodeCount ? each.value.minNodeCount : null
  max_nodes  = each.value.maxNodeCount != each.value.maxNodeCount ? each.value.maxNodeCount : null
}
