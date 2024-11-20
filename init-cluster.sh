#!/bin/bash

echo "Redis düğümlerinin başlatılması bekleniyor..."

# Redis düğümlerinin hazır olup olmadığını kontrol et
for i in {1..10}; do
  redis-cli -a CHANGE_PASSWORD -h redis-node-1 ping > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "Redis düğümleri başlatıldı!"
    break
  fi
  echo "Redis düğümleri hala başlatılıyor... tekrar denenecek ($i/10)"
  sleep 5
done

if [[ $i -eq 10 ]]; then
  echo "Redis düğümleri zaman aşımına uğradı. Script sonlanıyor."
  exit 1
fi

# Düğümleri sıfırla
echo "Redis düğümleri sıfırlanıyor..."
for node in redis-node-1 redis-node-2 redis-node-3 redis-node-4 redis-node-5 redis-node-6; do
  echo "Düğüm sıfırlanıyor: $node"
  redis-cli -a CHANGE_PASSWORD -h $node cluster reset soft
  if [[ $? -ne 0 ]]; then
    echo "Düğüm sıfırlanamadı: $node"
    exit 2
  fi
done
echo "Tüm düğümler sıfırlandı."

# Redis Cluster oluşturma
echo "Redis Cluster oluşturuluyor..."
output=$(redis-cli --cluster create \
  redis-node-1:6379 redis-node-2:6379 redis-node-3:6379 \
  redis-node-4:6379 redis-node-5:6379 redis-node-6:6379 \
  --cluster-replicas 1 \
  -a CHANGE_PASSWORD \
  --cluster-yes 2>&1)

if [[ $? -ne 0 ]]; then
  echo "Redis Cluster oluşturulamadı. Hata:"
  echo "$output"
  exit 3
fi

echo "Redis Cluster başarıyla oluşturuldu!"

# Cluster durumu kontrolü
echo "Cluster durumu kontrol ediliyor..."
cluster_info=$(redis-cli -a CHANGE_PASSWORD -h redis-node-1 cluster info)
if echo "$cluster_info" | grep -q "cluster_state:ok"; then
  echo "Cluster durumu: Sağlıklı"
else
  echo "Cluster durumu sağlıksız. Cluster bilgi:"
  echo "$cluster_info"
  exit 4
fi
