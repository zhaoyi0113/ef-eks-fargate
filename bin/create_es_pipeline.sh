PUT _ingest/pipeline/aws_metrics
{
  "version": 1,
  "processors": [
    {
      "script": {
        "source": "ctx.decoded = ctx.data.decodeBase64();"
      }
    },
    {
      "json": {
        "field": "decoded",
        "add_to_root": true
      }
    },
    {
      "remove": {
        "field": "decoded"
      }
    }
  ]
}