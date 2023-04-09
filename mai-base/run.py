#!/usr/bin/env python

import glob
import os
import subprocess
import sys
import time
import urllib.request
from html.parser import HTMLParser

class Parse(HTMLParser):
    __current_release_flag=False
    __current_release_date=None
    __magnet_link=None
    __checksum_flag=False

    def __init__(self, iso_release_date):
        super().__init__()
        self.__iso_release_date = iso_release_date
        self.reset()

    def handle_starttag(self, tag, attrs):
        if self.__current_release_date is not None:
            if tag == "a":  
                for name, link in attrs:
                    if link and name == "href" and link.startswith("magnet") == True:
                        self.__magnet_link=link
                        break

    def handle_data(self, data):
        if self.__current_release_date is None:
            if not self.__current_release_flag:
                if data.lower() == "current release:":
                    self.__current_release_flag = True
            else:
                self.__current_release_date = data.strip()
                if not self.__current_release_date > self.__iso_release_date:
                    raise NoNewReleaseException(self.__current_release_date)
        elif self.__magnet_link is not None:
            if not self.__checksum_flag:
                if data.lower() == "sha256:":
                    self.__checksum_flag = True
            else:
                raise DataParsedException(self.__current_release_date, self.__magnet_link, data.strip())

class NoNewReleaseException(Exception):
    def __init__(self, release_date):
        self.release_date = release_date

class DataParsedException(Exception):
    def __init__(self, release_date, magnet_link, checksum):
        self.release_date = release_date
        self.magnet_link = magnet_link
        self.checksum = checksum


def delete_last_line():
    sys.stdout.write('\x1b[2K')

if __name__ == '__main__':

    files = glob.glob('/var/lib/transmission/iso/archlinux-*.iso')
    if len(files) == 1:
        filename = files[0]
        iso_release_date=filename.rstrip('-x86_64.iso').lstrip('/var/lib/transmission/iso/archlinux-')
    elif len(files) == 0:
        iso_release_date = '2000.01.01'
    else:
        for file in files:
            print(file)
        exit('Multiple archlinux iso files found, exiting..')

    #Import HTML from a URL
    url = urllib.request.urlopen("https://archlinux.org/download")
    html = url.read().decode()
    url.close()

    p = Parse(iso_release_date)
    try:
        p.feed(html)
    except NoNewReleaseException as dataParsed:
        print(f"Latest version is: {dataParsed.release_date}")
        print("No new version released..")
    except DataParsedException as dataParsed:
        oldIsoFile = f"archlinux-{iso_release_date}-x86_64.iso"
        newIsoFile = f"archlinux-{dataParsed.release_date}-x86_64.iso"
        pathIsoDir = "/var/lib/transmission/iso"
        pathOldIso = f"{pathIsoDir}/{oldIsoFile}"
        pathOldChecksum = f"{pathOldIso}.sha256"
        pathNewIso = f"{pathIsoDir}/{newIsoFile}"
        pathNewChecksum = f"{pathNewIso}.sha256"
        checksum = f"{dataParsed.checksum} {newIsoFile}"

        print("Newer version found!")

        # Download new iso
        command = "transmission-remote"
        option2 = "--download-dir"
        oparam2 = f"{pathIsoDir}"
        option3 = "--add" 
        oparam3 = f"{dataParsed.magnet_link}"
        args = [command, option2, oparam2, option3, oparam3]
        print(' '.join(args))
        subprocess.run(args)

        dots = 0
        while not os.path.isdir(f"{pathIsoDir}"):
            print("Waiting for transmission to start" + "." * dots, end="\r", flush=True)
            time.sleep(1)
            delete_last_line()
            dots = dots + 1
            if(dots > 3):
                dots = 0
        print("Waiting for transmission to start..." + "\nDone.")

        percentage = 0
        dots = 0
        while not os.path.isfile(f"{pathNewIso}"):
            args = ["transmission-remote", "-l"]
            process1 = subprocess.run(args, check=True, capture_output=True)
            args = ["grep", f"{newIsoFile}"]
            process2 = subprocess.run(args, input=process1.stdout, capture_output=True)
            percentage = process2.stdout.decode("utf-8").split()[1]
            print(f"Downloading {newIsoFile} at {percentage}" + "." * dots, end="\r", flush=True)
            time.sleep(2)
            delete_last_line()
            dots = dots + 1
            if(dots > 3):
                dots = 0
        print(f"Downloading {newIsoFile} at {percentage}..\nDone.")

        # delete torrent
        args = ["transmission-remote", "-l"]
        process1 = subprocess.run(args, check=True, capture_output=True)
        args = ["grep", f"{newIsoFile}"]
        process2 = subprocess.run(args, input=process1.stdout, capture_output=True)
        torrentID = process2.stdout.decode("utf-8").split()[0]
        args = ["transmission-remote", "-t", torrentID, "-r"]

        subprocess.run(args)

        # Write checksum file
        with open(pathNewChecksum, 'w') as file:
            file.write(checksum + '\n')
         
        # Delete old iso & checksum files 
        if os.path.exists(pathOldIso):
            os.remove(pathOldIso)
        if os.path.exists(pathOldChecksum):
            os.remove(pathOldChecksum)

        iso_release_date = dataParsed.release_date
    
    print("Starting packer application..")
        
    # Run packer
    command = "packer"
    subcommand = "build"
    option1 = "-var"
    oparam1 = f"iso_release_date={iso_release_date}" 
    template = "safenetwork-community-installer.pkr.hcl"
    args = [command, subcommand, option1, oparam1, template]
    print(' '.join(args)) 

    subprocess.run(args)
