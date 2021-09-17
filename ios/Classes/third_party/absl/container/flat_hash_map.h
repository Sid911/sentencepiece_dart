// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.!

#ifndef ABSL_CONTAINER_FLAT_HASH_MAP_
#define ABSL_CONTAINER_FLAT_HASH_MAP_

#include <unordered_map>

namespace absl {

template <typename K, typename V, typename Hash = std::hash<K>,
          typename Eq = std::equal_to<K>,
          typename Allocator = std::allocator<std::pair<const K, V>>>
using flat_hash_map = std::unordered_map<K, V, Hash, Eq, Allocator>;

}

#endif  // ABSL_CONTAINER_FLAT_HASH_MAP_
