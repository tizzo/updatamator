#!/bin/bash -e

##
# This script is largely ripped off of apticron
# and repurposed to spit JSON and not email.
# and with less features.
##

# By default we have no profile
LISTCHANGES_PROFILE=""

# Set $DIRCACHE
eval `/usr/bin/apt-config shell DIRCACHE Dir::Cache`

# Set the SYSTEM
SYSTEM=`/bin/hostname`

# Set the IPADDRESSNUM
IPADDRESSNUM="1"


# Source lsb-release so we know what distribution we are
DISTRIB_ID="Debian"    # Default to Debian
[ -e /etc/lsb-release ] && . /etc/lsb-release

# Source the config file
[ -e /etc/apticron/apticron.conf ] && . /etc/apticron/apticron.conf

# Force resolving and showing all FQDNs
if [ -n "$ALL_FQDNS" ] ; then
  SYSTEM=`/bin/hostname --all-fqdns`
fi

if [ -z "$IPADDRESSES" ] && [ -x /sbin/ip ]; then
  # Set the IPv4 addresses
  IPADDRESSES=`(echo $( /bin/hostname --all-ip-addresses ) ;
         /sbin/ip -f inet addr show scope global 2> /dev/null | \
         /bin/grep "scope global" |\
         /usr/bin/head -$IPADDRESSNUM |\
         /usr/bin/awk '{ print $2 }' |\
         /usr/bin/cut -d/ -f1) |\
         /usr/bin/uniq || true`

  # Set the IPv6 addresses
  IPADDRESSES="$IPADDRESSES `/sbin/ip -f inet6 addr show scope global 2> /dev/null | \
                             /bin/grep "scope global" | \
           /usr/bin/head -$IPADDRESSNUM |\
           /usr/bin/awk '{ print $2 }' |\
           /usr/bin/cut -d/ -f1`"
fi

# Turn our list of addresses into nicely formatted output
ADDRESSES=""
if [ -n "$IPADDRESSES" ] ; then
  for address in $IPADDRESSES; do
    # Add the Address
    ADDRESSES="${ADDRESSES} ${address}"
  done

  ADDRESSES=`echo $ADDRESSES | /usr/bin/fmt -w68 |\
       /bin/sed 's/^/\t[ /;s/\$/ ]/'`
  ADDRESSES=`echo -e "\n$ADDRESSES"`
fi

# update the package lists
/usr/bin/apt-get -qq update || true

# get the list of packages which are pending an upgrade
PKGNAMES=`/usr/bin/apt-get -q -y --ignore-hold --allow-unauthenticated -s dist-upgrade | \
          /bin/grep ^Inst | /usr/bin/cut -d\  -f2 | /usr/bin/sort`

# workaround to handle apt-get installing packages hold by aptitude. See #137771.
APTITUDE_HOLDS=`grep "^State: 2" -B 2 /var/lib/aptitude/pkgstates 2>/dev/null |grep "^Package: .*$" |cut -d" " -f 2`
DSELECT_HOLDS=`dpkg --get-selections |grep "hold$" |cut -f1`

if [ "$NOTIFY_HOLDS" = "0" ]; then
  # packages hold by aptitude don't go to the upgrading candidates list
  for p in $APTITUDE_HOLDS; do
    PKGNAMES=`echo $PKGNAMES |sed "s/\(^\| \)$p\( \|$\)/ /g;s/^ //g"`
  done
  # packages hold by dselect don't go to the upgrading candidates list
  for p in $DSELECT_HOLDS; do
    PKGNAMES=`echo $PKGNAMES |sed "s/\(^\| \)$p\( \|$\)/ /g;s/^ //g"`
  done
fi

if [ "$NOTIFY_NEW" = "0" ]; then
  # new packages don't go to the upgrading candidates list (see #531002)
  for p in $PKGNAMES; do
          if [ -z "`dpkg -s $p 2>/dev/null| grep '^Status: install ok installed'`" ] ; then
            PKGNAMES=`echo $PKGNAMES |sed "s/\(^\| \)$p\( \|$\)/ /g;s/^ //g"`
    fi
  done
fi

NUM_PACKAGES=`echo $PKGNAMES |wc -w`

function json_escape(){
  echo -n "$1" | python -c 'import json,sys; print json.dumps(sys.stdin.read())'
}

if [ -n "$PKGNAMES" ] ; then

  # do the upgrade downloads
  /usr/bin/apt-get --ignore-hold -qq -d --allow-unauthenticated --force-yes dist-upgrade > /dev/null
  PKGPATH="/${DIRCACHE}archives/"
  JSON_STRING=''
  first='true'
  for PKG in $PKGNAMES ; do
    if [ "$first" == 'false' ] ; then
      JSON_STRING="$JSON_STRING, "
    fi
    first='false'
    VER=`LC_ALL=C /usr/bin/apt-cache policy $PKG |\
         /bin/grep Candidate: | /usr/bin/cut -f 4 -d \ `
    VERFILE=`echo "$VER" | /bin/sed -e "s/:/%3a/g"`
    if ls ${PKGPATH}${PKG}_${VERFILE}_*.deb >& /dev/null ; then
      DEB="${PKGPATH}${PKG}_${VERFILE}_*.deb"
      NOTES=`/usr/bin/apt-listchanges --which=both --headers -f text $DEB`
    fi
    NOTES=`json_escape "$NOTES"`
    ELEMENT=`printf '"%s": { "version": "%b", "release_notes": %s }' ${PKG} ${VER} "${NOTES}"`
    JSON_STRING="$JSON_STRING $ELEMENT"
  done
  JSON_STRING="{ \"hostname\": \"$SYSTEM\", \"updates\": { $JSON_STRING } }"
  echo $JSON_STRING

  # TODO: We're not handling the package holds reported by apticron.'
fi


exit 0
