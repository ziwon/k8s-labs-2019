# cosmos-validators

This will create 3 validators on your cluster with host network.  In production, you should configure persistent volume for each node.

```sh
$ git clone git@github.com:ziwon/yak8s.git
$ cd yak8s
$ make kind-cluster-up
$ export KUBECONFIG="$(kind get kubeconfig-path --name="1")"\n
$ make kinc-cluster-info # regenerate kubecofig for kind cluster
$ k create namespace blockchain
$ k apply cosmos/validator.yaml -n blockchain
$ k get pods -o wide -w
```

The outputs are:
```sh
$ k logs -f gaia-0 gaiad
...
I[2019-06-04|10:40:09.268] Executed block                               module=state height=33 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:09.283] Committed state                              module=state height=33 txs=0 appHash=88EABDEC9DD05B9204706E0FDF6BBA4CE2574B63A7F476C1097D72BCF30B52DE
I[2019-06-04|10:40:14.854] Executed block                               module=state height=34 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:14.860] Committed state                              module=state height=34 txs=0 appHash=B012D5023FA49A596DC58D5F7F9AD51098ACE4072CED70D6A79B8300F16AA833
I[2019-06-04|10:40:20.190] Executed block                               module=state height=35 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:20.217] Committed state                              module=state height=35 txs=0 appHash=750EB13BB3457215FC12AA706A8BDA10F6B2360F4ACBD09C8BE01D47D1A3E25B
I[2019-06-04|10:40:25.653] Executed block                               module=state height=36 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:25.674] Committed state                              module=state height=36 txs=0 appHash=814A52452216F2986736EFF7897DE9085496EEEA02E2F7731AE1C3A0B043F97E
I[2019-06-04|10:40:31.236] Executed block                               module=state height=37 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:31.289] Committed state                              module=state height=37 txs=0 appHash=FF74BFB2E9BE4EC78C22F5C1F76D2F46C5A05AF8687E6AA574A1FAD9EDE11FCC
I[2019-06-04|10:40:37.714] Executed block                               module=state height=38 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:37.824] Committed state                              module=state height=38 txs=0 appHash=D05625014F1EAFF01754DBB89A438EC6E73C340AE276EFD331012F197AB8DD07
I[2019-06-04|10:40:44.363] Executed block                               module=state height=39 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:44.501] Committed state                              module=state height=39 txs=0 appHash=507E1A87640FF9F11DB580380E422D5E9205A033E383DFFBEEB8671A24F9FB83
I[2019-06-04|10:40:51.610] Executed block                               module=state height=40 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:51.725] Committed state                              module=state height=40 txs=0 appHash=E0F1EBA2D3AC506354463A5E680A4BF04B175EC72B69F2C6D9881E04C99C73F1
I[2019-06-04|10:40:59.478] Executed block                               module=state height=41 validTxs=0 invalidTxs=0
I[2019-06-04|10:40:59.824] Committed state                              module=state height=41 txs=0 appHash=B3B0B29DFCC9C468EDFDF4A28A89378ABD49D64CCE2B0F7C3E4B1DCC16595314
E[2019-06-04|10:41:05.491] Dialing failed                               module=pex addr=b7632037c69bbdfc8be7f9104cd0a3742d735882@172.17.0.6:26656 err="filtered CONN<172.17.0.6:26656>: duplicate CONN<172.17.0.6:26656>" attempts=5
I[2019-06-04|10:41:05.779] Executed block                               module=state height=42 validTxs=0 invalidTxs=0
I[2019-06-04|10:41:06.998] Committed state                              module=state height=42 txs=0 appHash=CC22570FDF8EC79F3DD21E9350A6D5E86843E313C6330223B2CCABF77DA98537
I[2019-06-04|10:41:10.853] Executed block                               module=state height=43 validTxs=0 invalidTxs=0
I[2019-06-04|10:41:10.872] Committed state                              module=state height=43 txs=0 appHash=A8D2247783F9473B910A75882699B00FF5B7787402A255B748A3D47DE9BD0B70
```
