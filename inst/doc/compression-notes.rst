Compression Data
================

The table below presents the results of compression tests on a collection of 142 SAS7BDAT data files (sources in ``data/``). The 'type' field represents the type of compression, 'ctime' is the compression time (in seconds), 'dtime' is the decompression time, and the 'compression ratio' field holds the cumulative disk usage (in megabytes) before and after compression. Although the ``xz`` algorithm requires significantly more time to compress these data, the decompression time is on par with gzip.

=============	======	======	=========================
type		ctime	dtime	compression ratio
=============	======	====== 	=========================
gzip -9		76.7s	2.6s	541M / 30.3M = 17.9
bzip2 -9	92.7s	11.2s	541M / 19.0M = 28.5
xz -9		434.2s	2.7s	541M / 12.8M = 42.3
=============	======	======	=========================
