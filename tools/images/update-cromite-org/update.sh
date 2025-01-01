#!/bin/bash

install_rclone() {
  wget https://github.com/rclone/rclone/releases/download/v1.64.0/rclone-v1.64.0-linux-amd64.zip
  unzip rclone-v1.64.0-linux-amd64.zip
  rm rclone-v1.64.0-linux-amd64.zip

  # mkdir -p  ~/.config/rclone
  # echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf
}

test -d rclone-v1.64.0-linux-amd64 || install_rclone
export rclone=rclone-v1.64.0-linux-amd64/rclone

rm -rf filters || true
mkdir filters

while true
do

  pushd filters
  
  KO=0
  curl -O https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/abpindo+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/abpvn+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/bulgarian_list+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/dandelion_sprouts_nordic_filters+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistczechslovak+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistdutch+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistgermany+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/israellist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistitaly+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistlithuania+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistpolish+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistportuguese+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easylistspanish+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/indianlist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/koreanlist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/latvianlist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/liste_ar+liste_fr+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/liste_fr+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/rolist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/ruadlist+easylist.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/i_dont_care_about_cookies.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/fanboy-notifications.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/easyprivacy.txt || KO=1
  curl -O https://easylist-downloads.adblockplus.org/fanboy-social.txt || KO=1

  NOW=$(date +"%Y-%m-%dT%H:%M:%S%z")
  echo Last Update $NOW > LAST-UPDATE.txt

  popd

  $rclone sync filters ftp:www.cromite.org/filters --log-level INFO
  $rclone sync filters ftp:www.cromite.org/filters --log-level INFO

  echo "You can stop now"
  sleep 1h

done