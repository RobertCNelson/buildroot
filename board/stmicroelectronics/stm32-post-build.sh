#!/bin/sh

# Kernel is built without devpts support
sed -i '/^devpts/d' ${TARGET_DIR}/etc/fstab

# Kernel is built without network support
rm -f ${TARGET_DIR}/etc/init.d/S40network
rm -rf ${TARGET_DIR}/etc/network/

cat > ${TARGET_DIR}/usr/bin/serial_esp.sh <<-__EOF__
#!/bin/sh

setup_stty () {
    #stty -F /dev/ttySTM1 115200 -icanon min 0 time 30
    if [ ! -f /tmp/stty.setup ] ; then
        touch /tmp/stty.setup
        stty -F /dev/ttySTM1 115200
        echo 'AT+LEDON' > /dev/ttySTM1
        sleep 0.1
        echo 'AT+RST' > /dev/ttySTM1
        echo 'Wait for reset (10 seconds)'
        sleep 10
        echo 'AT+LEDOFF' > /dev/ttySTM1
    fi
}

grab_temp () {
    in_temp_raw=\$(cat /sys/bus/iio/devices/iio:device0/in_temp_raw || true)
    in_temp_offset=\$(cat /sys/bus/iio/devices/iio:device0/in_temp_offset || true)
    in_temp_scale=\$(cat /sys/bus/iio/devices/iio:device0/in_temp_scale || true)

    if [ ! "x\${in_temp_raw}" = "x" ] && [ ! "x\${in_temp_offset}" = "x" ] && [ ! "x\${in_temp_scale}" = "x" ] ; then
        temp=\$(echo "\${in_temp_raw} + \${in_temp_offset}" | bc)
        temp=\$(echo "scale=5; \${temp} * \${in_temp_scale}" | bc)
        temp=\$(echo "scale=3; \${temp} / 1000" | bc)
        temp=\$(echo "scale=3; \${temp} * 1.8" | bc)
        temp=\$(echo "scale=3; \${temp} + 32" | bc)
        echo \${temp}
    fi
}

send_data () {
    echo 'AT+LEDON' > /dev/ttySTM1
    sleep 0.2
    echo 'AT' > /dev/ttySTM1
    sleep 1
    echo 'AT+CIPMUX=1' > /dev/ttySTM1
    sleep 1
    echo 'AT+CIPSTART=4,"TCP","gfnd.rcn-ee.org",81' > /dev/ttySTM1
    sleep 1
    echo 'AT+CIPSEND=4,32'  > /dev/ttySTM1
    sleep 1
    echo "GET /stdevcon?temp='\$temp'F"  > /dev/ttySTM1
    sleep 1
    echo 'AT+CIPCLOSE' > /dev/ttySTM1
    sleep 1.5
    echo 'AT' > /dev/ttySTM1
    sleep 1.5
    echo 'AT+LEDOFF' > /dev/ttySTM1
    sleep 0.2
}

setup_stty

if [ ! -f /tmp/lock.txt ] ; then
    touch /tmp/lock.txt

    while :
    do
        grab_temp
        send_data
        sleep 15
    done
fi

__EOF__

chmod +x ${TARGET_DIR}/usr/bin/serial_esp.sh

#cat > ${TARGET_DIR}/etc/init.d/S99demo <<-__EOF__
##!/bin/sh
#
#/bin/sh /usr/bin/serial_esp.sh
#__EOF__
#
#chmod +x ${TARGET_DIR}/etc/init.d/S99demo


