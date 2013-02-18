
mkdir -p /tmp/dca_useh
mount 162.86.11.123:/export/softdca /tmp/dca_useh
cd /tmp/dca_useh/previews

if [ -a '/tmp/dca_useh/previews/previewAIX.ksh' ]
then
        ksh /tmp/dca_useh/previews/previewAIX.ksh useh
        if [ -a "/tmp/dca_useh/previews/outputs/AIX/`hostname`/" ]
        then
                cat /tmp/dca_useh/previews/outputs/`uname`/`hostname`/*
        fi
fi

cd /
umount /tmp/dca_useh
rmdir /tmp/dca_useh
exit
