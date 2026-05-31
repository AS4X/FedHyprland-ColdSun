#!/bin/bash

stage_1() {
echo "#######################################"
echo "#####---      New Packages     ---#####"
echo "#######################################"

#########---   RPM Packages   ---###########
echo -e "###--- Running Desktop config Stage 1 ---###\n Installing new packages."

echo -e "Enabling additional repositories."
echo -e "Enabling Alacritty repository."
dnf copr enable pschyska/alacritty                   
NEWPKG=(git zsh alacritty micro nmap btop keepassxc)

echo -e "Installing packages through RPM...\n"
for pkg in "${NEWPKG[@]}"; do
	if ! rpm -q "$pkg" 2>/dev/null; then
		echo -e "Installing $pkg"
		dnf -y install "$pkg"
	else
		echo -e "Package" $(rpm -q "$pkg") "is already installed."
	fi
done
#######################################
#//        Unmanaged Packages       \\#
#// #####                      #### \\#
echo -e "Installing unmanaged packages!\n"

############### Zen Browser ##################

if [ -d /opt/zen ]; then
	echo "Zen Browser is already installed!"
else
	echo -e "Installing Zen Browser"
	#Download
	wget https://github.com/zen-browser/desktop/releases/latest/download/zen.linux-x86_64.tar.xz
	tar -xf zen.linux-x86_64.tar.xz
	rm zen.linux-x86_64.tar.xz #Cleanup
    mv zen /opt/zen/ # "Installation"
	#Registering application PATH
	echo -e 'export PATH="$PATH:/opt/zen"' >> /home/$USERNAME/.zshrc
	###########    Desktop Shortcut     ################
	echo -e '[Desktop Entry]\n Name=Zen Browser\n Exec=/opt/zen/zen\n Comment=Web Browser\n Terminal=false\n Icon=/opt/zen/icons/icon.png\n Type=Application' > /home/$USERNAME/Desktop/zen.desktop
	wget https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Zen_Browser_logo_%28red_circles%29.svg/1280px-Zen_Browser_logo_%28red_circles%29.svg.png #Icon download
	mv 1280px-Zen_Browser_logo_\(red_circles\).svg.png /opt/zen/icons/icon.png
	chmod +x /home/$USERNAME/Desktop/zen.desktop
fi

################# VS Code ####################
if rpm -q code 2>/dev/null; then
	echo "VS Code is already installed!"
else
	echo -e "Installing VS Code"
	#Importing keys and repo
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
	echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
	#Installation
	dnf check-update
	dnf install -y code
fi
################ Sublime Txt ###############

if rpm -q sublime-text 2>/dev/null; then
	echo "Sublime Text is already installed!"
else
	rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
	dnf config-manager addrepo --from-repofile=https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
	dnf install -y sublime-text
fi
################ Oh My Zsh! ################

if [ -f /home/$USERNAME/.zshrc ]; then
	echo "Oh My Zsh configuration file found"
else
	echo "Downloading Oh My Zsh!"
	su - "$USERNAME" -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
fi
# Configure Shell theme!
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="af-magic"/' /home/$USERNAME/.zshrc
# Enabling Zsh
chsh -s /bin/zsh $USERNAME
source /home/$USERNAME/.zshrc

### END STAGE 1 ###
}

stage_2() {

echo "#######################################"
echo "#####---       Debloater       ---#####"
echo "#######################################"
echo -e "Running Desktop config Stage 2\n Detecting unnecessary packages"

GROUPPKG=(desktop-accessibility kde-apps kde-media kde-pim)
for grouppkg in "${GROUPPKG[@]}"; do
	if dnf group list --installed | grep -q $grouppkg 2>/dev/null; then
		echo -e "Uninstalling $grouppkg"
		dnf -y group remove "$grouppkg"
	else
		echo -e "No group packages to remove.\n Proceeding with next stage."
	fi
done

PKG=(kpat dragon okular krdc kwrite konsole kitty akregator kmail kmines kmouth kmahjongg kolourpaint spectacle kamoso ark)
for pkg in "${PKG[@]}"; do
	if rpm -q "$pkg" 2>/dev/null; then
		echo -e "Uninstalling $pkg"
		dnf -y remove "$pkg"
	else
		echo -e "No packages to remove.\n Proceeding with next stage."
	fi
done
### END STAGE 2 ###
}

stage_3(){

echo "#######################################"
echo "#####---     System Config     ---#####"
echo '#######################################'

select_hostname(){
### Select desired hostname

echo -e "Select the desired computer hostname\n"
read HOSTNAME
HOSTNAME=$HOSTNAME

if [ ! $HOSTNAME = '' ]; then
	echo -e "\nYou have entered $HOSTNAME"
	hostnamectl hostname $HOSTNAME	# Hostname
else
	echo -e "Please enter a valid hostname"
	select_hostname # Run function again should input be invalid
fi
}

set_theme(){

	###--- Install Orchis
	echo "..............................."
	echo ".......     Themes     ........"
	echo '...............................'
	echo -e "\nInstalling Orchis theme\n"

	if [ -d /home/$USERNAME/.local/share/plasma/desktoptheme/Orchis-dark ]; then
		echo "Orchis theme is already installed"
	else
		git clone https://github.com/vinceliuice/Orchis-kde.git
		chmod +x ./Orchis-kde/install.sh
		bash ./Orchis-kde/install.sh
		su - "$USERNAME" -c 'sh -c "$(plasma-apply-lookandfeel -a "com.github.vinceliuice.Orchis-dark")"'
	fi
}

set_desktop(){

	if [ -d /home/$USERNAME/Pictures/Bck-img/ ]; then
		echo "Folder for background images detected"
	else
		su $USERNAME sh -c "$(mkdir /home/$USERNAME/Pictures/Bck-img/)"
		echo "Folder for background images has been created"
	fi
	###--- Download background images
	FILENAMES=('neon-liquid1.jpg' 'neon-liquid2.jpg' 'shapes1.jpg')
	for img in "${FILENAMES[@]}"; do
		echo "Downloading image: $img"
		curl -fsSL "https://raw.githubusercontent.com/AS4X/Fedora-ColdSun/refs/heads/main/img/$img" -o "/home/$USERNAME/Pictures/Bck-img/$img"
	done
	plasma-apply-wallpaperimage "/home/$USERNAME/Pictures/Bck-img/${FILENAMES[1]}"

	###--- Download icon pack
	TMPDOTLOCAL="/home/$USERNAME/tmpdotlocal"
	mkdir $TMPDOTLOCAL
	curl -fL "https://raw.githubusercontent.com/AS4X/Fedora-ColdSun/refs/heads/main/src/dotlocal-share-icons.tar" -o "$TMPDOTLOCAL/dotlocal-share-icons.tar"
	tar -xf "$TMPDOTLOCAL/dotlocal-share-icons.tar"

	###--- KDE Desktop Settings
	DOTCONF=(dolphinrc 
	kdeglobals 
	kdeglobalshortcutsrckwinrc 
	kwinrc
	plasma-localerc 
	plasma-org.kde.plasma.desktop-appletsrc 
	plasmarc 
	plasmashellrc
	)
	# TMPDOTCONF="/home/$USERNAME/tmpdotconf"
	# mkdir $TMPDOTCONF
	for file in "${DOTCONF[@]}"; do
		echo "Downloading file: $file"
		curl -fsSL "https://raw.githubusercontent.com/AS4X/Fedora-ColdSun/refs/heads/main/src/dotconfig/$file" -o "/home/$USERNAME/.config/$file"
	done
}

echo -e "\nUpdate computer's hostname? Enter Y/N:\n"
read -n 1 OPTION

if [ $OPTION = 'y' ]; then
	select_hostname ###--- Run function to update hostname
elif [ $OPTION = 'n' ]; then
	echo -e "\nSkipping computer hostname update."
else
	echo -e "\nInvalid selection, skipping computer hostname update."
fi
set_theme ###--- Run function to set desktop theme
set_desktop ###--- Run function to set desktop background
### END STAGE 3 ###
}

echo "##################################################"
echo "###\\\....  Asyx Desktop Configuration  ....///###"
echo "##################################################"

####################################
#### Configure Global Variables ####
####################################

### Username

if [ $USER = 'root' ]; then
	echo -e "Script is currently running as: $USER.\nPlease input the name of the target user:"
	read USERNAME
	echo -e "\nYou have entered user: $USERNAME\n"
else
	echo -e "Script is currently running as: $USER.\n Please run the script as root, then configure the name of the target user on the script."
	exit 1
fi

### Detect validity of user.

echo -e "Running user validation..."
if [ -d /home/$USERNAME ]; then
	echo "Valid user detected!"
elif [ $USERNAME = 'root' ]; then
	echo -e "Although script may run as root user, the root account may not be selected for desktop configuration purposes. Re-run script and select a different user.\n Exiting script...\n"
	exit 1
else
	echo "User not found. Exiting script..."
	exit 1
fi

###---	Init stages

stage_1 ###--- Run Stage 1!
stage_2 ###--- Run Stage 2!
stage_3 ###--- Run Stage 3!
