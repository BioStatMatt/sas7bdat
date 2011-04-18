Compression Data
================

The table below presents the results of compression tests on a collection of 142 SAS7BDAT data files (sources in ``data/``). The 'type' field represents the type of compression, 'ctime' is the compression time (in seconds), 'dtime' is the decompression time, and the 'compression ratio' field holds the cumulative disk usage (in bytes) before and after compression. Although the ``xz`` algorithm requires significantly more time to compress these data, the decompression time is on par with gzip.

=============	=====	=====	=========================
type		ctime	dtime	compression ratio
=============	=====	===== 	=========================
gzip -9		76.7	2.6	541417472/30289920 = 17.9
bzip2 -9	92.7	11.2	541417472/19030016 = 28.5
xz -9		434.2	2.7	541417472/12791808 = 42.3
=============	=====	=====	=========================
