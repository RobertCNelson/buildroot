#!/bin/sh

# Kernel is built without devpts support
sed -i '/^devpts/d' ${TARGET_DIR}/etc/fstab

# Kernel is built without network support
rm -f ${TARGET_DIR}/etc/init.d/S40network
rm -rf ${TARGET_DIR}/etc/network/

cat > ${TARGET_DIR}/usr/bin/serial_esp.sh <<-__EOF__
#!/bin/sh

setup_stty () {
    #stty -F /dev/ttyS1 115200 -icanon min 0 time 30
    if [ ! -f /tmp/stty.setup ] ; then
        touch /tmp/stty.setup
        stty -F /dev/ttyS1 115200
        echo 'AT+LEDON' > /dev/ttyS1
        sleep 0.1
        echo 'AT+RST' > /dev/ttyS1
        echo 'Wait for reset (5 seconds)'
        sleep 5
        echo 'AT+LEDOFF' > /dev/ttyS1
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
    echo 'AT+LEDON' > /dev/ttyS1
    sleep 0.1
    echo 'AT+CIPMUX=1' > /dev/ttyS1
    sleep 0.5
    echo 'AT+CIPSTART=4,"TCP","gfnd.rcn-ee.org",81' > /dev/ttyS1
    sleep 0.5
    echo 'AT+CIPSEND=4,34'  > /dev/ttyS1
    sleep 0.5
    #GET /stdevcon/ = 14
    #'\$temp'=72.330=6
    #F HTTP/1.1 = 10
    #+4
    echo "GET /stdevcon/'\$temp'F HTTP/1.1" > /dev/ttyS1
    sleep 0.5
    echo '' > /dev/ttyS1
    sleep 0.5
    echo 'AT+CIPCLOSE' > /dev/ttyS1
    sleep 0.5
    echo 'AT+LEDOFF' > /dev/ttyS1
    sleep 0.1
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

#chmod +x ${TARGET_DIR}/usr/bin/serial_esp.sh
#
#cat > ${TARGET_DIR}/etc/init.d/S99demo <<-__EOF__
##!/bin/sh
#
#/bin/sh /usr/bin/serial_esp.sh
#__EOF__

#chmod +x ${TARGET_DIR}/etc/init.d/S99demo


