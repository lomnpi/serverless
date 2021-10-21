import hashlib
import boto3

__all__ = ["handler"]

s3 = boto3.resource("s3")

def handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        content = s3.Object(bucket, key).get()

        s3.Object(bucket, key + ".sha256").put(
            Body=digest(content["Body"]).encode("ascii"),
            ContentType="text/plain",
            ServerSideEncryption="AES256",
        )

def digest(stream):
    hash = hashlib.sha256()

    for chunk in stream.iter_chunks(chunk_size=1024):
        hash.update(chunk)

    return hash.hexdigest()
