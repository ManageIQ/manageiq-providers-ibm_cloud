import os
import sys
import json
import base64

from pathlib import Path
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

import ibm_boto3
from ibm_botocore.client import Config, ClientError

wrkdir = os.path.dirname(os.path.realpath(__file__))

key  = os.environ.get('CREDS_AES_KEY')
iv   = os.environ.get('CREDS_AES_IV')
encr = Path(wrkdir + '/credentials.aes').read_text()

key  = base64.b64decode(key)
iv   = base64.b64decode(iv)
encr = base64.b64decode(encr)

cipher = AES.new(key, AES.MODE_CBC, iv)
creds = json.loads(unpad(cipher.decrypt(encr), AES.block_size).decode('utf-8'))

COS_ENDPOINT = creds['url_endpoint']
COS_BUCKET_LOCATION = creds['bucket_name']
COS_API_KEY_ID = creds['apikey']
COS_INSTANCE_CRN = creds['resource_instance_id']
IMAGE_FILE = sys.argv[1]

cos = ibm_boto3.resource("s3", ibm_api_key_id=COS_API_KEY_ID, ibm_service_instance_id=COS_INSTANCE_CRN, config=Config(signature_version="oauth"), endpoint_url=COS_ENDPOINT)

def upload_file(bucket_name, item_name, file_path):
    part_size = 1024 * 1024 * 5
    file_threshold = 1024 * 1024 * 5

    cos_cli = ibm_boto3.client("s3",
        ibm_api_key_id=COS_API_KEY_ID,
        ibm_service_instance_id=COS_INSTANCE_CRN,
        config=Config(signature_version="oauth"),
        endpoint_url=COS_ENDPOINT
    )

    transfer_config = ibm_boto3.s3.transfer.TransferConfig(
        multipart_threshold=file_threshold,
        multipart_chunksize=part_size
    )

    transfer_mgr = ibm_boto3.s3.transfer.TransferManager(cos_cli, config=transfer_config)

    try:
        future = transfer_mgr.upload(file_path, bucket_name, item_name)
        future.result()
    finally:
        transfer_mgr.shutdown()


upload_file(COS_BUCKET_LOCATION, os.path.basename(IMAGE_FILE), IMAGE_FILE)