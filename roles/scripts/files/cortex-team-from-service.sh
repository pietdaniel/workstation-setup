#!/usr/bin/env bash

SERVICE_NAME="$1"
API_KEY="eyJ6aXAiOiJHWklQIiwiYWxnIjoiSFM1MTIifQ.H4sIAAAAAAAA_02NsQ6CMBRF_-XNNOG1pQibQwdiYoziwETa8hIbCaAUIzH-u2Vzuzm5J-cD82KhBIQEwjpRnPtT1V4v-hyJG_vez34cWvMafWcGtx2csAXijrOMZ5xJMsistCnLOyeF5MS5ElG-08rMEm40BO9MoI496bHQHNhf6KCbVh_rqm6i4U2AEnMlUqUyxAToPW2gkIoLqcT3BzlkxACuAAAA.-nVf-esvVYXdcnE_fte4zp2uKdNDP4wqcc2D1gBifvhPKo3kLZG4MsNbKV73yFUKMt9rirx-DgL40w_lyNITYA"

curl -X GET "https://cortex-api.eng.roktinternal.com/api/v1/services/$SERVICE_NAME" \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" | jq
