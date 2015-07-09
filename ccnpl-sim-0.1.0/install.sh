#! /bin/bash

#CCN-PL-SIM simulator installation procedure

folder=${PWD}/ccnpl-sim


# Required packages developped and maintained by Antonio Carzaniga et al.
sff="sff-1.9.5"
ssbg="ssbg-1.3.5"
ssim="ssim-1.7.6"
ssimp="ssimp-1.1.5"

# Required packages developped and maintained by Luca Muscariello, Massimo Gallo et al.
# based on cbnsim-1.1.3 and cbcbsim-1.0.2 developped and not anymore maintained by Antonio Carzaniga.
cbnsim="cbnsim-1.1.3"
cbcbsim="cbcbsim-1.0.2"

# Retrieve, compile, install.

wget http://www.inf.usi.ch/carzaniga/siena/forwarding/$sff.tar.gz
svn co https://ccnpl-sim.googlecode.com/svn/tags/$sff-patch
tar xvzf $sff.tar.gz
cd $sff/ 
patch -p1 < ../$sff-patch/$sff-patch.patch
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure --prefix=${folder}/sff && make install && cd ../

wget http://www.inf.usi.ch/carzaniga/siena/forwarding/$ssbg.tar.gz
tar xvzf $ssbg.tar.gz
cd $ssbg/ 
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure --prefix=${folder}/ssbg && make install && cd ../

wget http://www.inf.usi.ch/carzaniga/ssim/$ssim.tar.gz
tar xvzf $ssim.tar.gz
cd $ssim/ 
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure --prefix=${folder}/ssim && make install && cd ../

wget http://www.inf.usi.ch/carzaniga/siena/forwarding/$ssimp.tar.gz
tar xvzf $ssimp.tar.gz
cd $ssimp/ 
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure	--with-sff=${folder}/sff \
		--prefix=${folder}/ssimp && make install && cd ../


svn co https://ccnpl-sim.googlecode.com/svn/tags/$cbnsim
cd $cbnsim/
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure	--with-ssim=${folder}/ssim \
		--with-sff=${folder}/sff \
		--with-ssimp=${folder}/ssimp \
		--with-ssbg=${folder}/ssbg \
		--prefix=${folder}/cbnsim && make install && cd ../

svn co https://ccnpl-sim.googlecode.com/svn/tags/$cbcbsim
cd $cbcbsim/
rm -f config.status config.cache config.log configure.lineno config.status.lineno
./configure	--with-ssim=${folder}/ssim \
		--with-sff=${folder}/sff \
		--with-ssimp=${folder}/ssimp \
		--with-ssbg=${folder}/ssbg \
		--with-cbnsim=${folder}/cbnsim \
		--prefix=${folder} && make install && cd ../

sudo ldconfig ${folder}/ssbg/lib/ ${folder}/cbnsim/lib/ ${folder}/ssimp/lib/ ${folder}/sff/lib/ ${folder}/ssim/lib/




