#!/bin/bash

stage_1() {
#######################################
#####---     Customization     ---#####
#######################################

#########---   RPM Packages   ---###########
echo -e "Running Desktop config Stage 1\n Installing new packages."

echo -e "Enabling additional repositories."
echo -e "Enabling Alacritty repository."
dnf copr enable pschyska/alacritty                   
NEWPKG=(git vscode alacritty)

echo -e "Installing packages through RPM...\n"
for pkg in "${NEWPKG[@]}"; do
	if ! rpm -q "$pkg" 2>/dev/null; then
		echo -e "Installing $pkg"
		dnf -y install "$pkg"
	else
		echo -e "Package" $(rpm -q "$pkg") "is already installed."
	fi
done
##############################################

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
	echo -e 'export PATH="$PATH:/opt/zen"' > /home/$USERNAME/.zshrc
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
################ Oh My Zsh! ################

if [ -f /home/$USERNAME/.zshrc ]; then
	echo "Oh My Zsh configuration file found"
else
	echo "Downloading Oh My Zsh!"
	su $USERNAME sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
# Configure Shell theme!
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="af-magic"/' /home/$USERNAME/.zshrc
# Enabling Zsh
chsh -s /bin/zsh $USERNAME
source ~/.zshrc

### END STAGE 1 ###
}

stage_2() {
#######################################
#####---       Debloater       ---#####
#######################################
echo -e "Running Desktop config Stage 2\n Detecting unnecessary packages"

GROUPPKG=(kde-apps kde-media)
for grouppkg in "${GROUPPKG[@]}"; do
	if dnf group list --installed | grep -q $grouppkg 2>/dev/null; then
		echo -e "Uninstalling $pkg"
		dnf -y group remove "$pkg"
	else
		echo -e "No packages to remove.\n Proceeding with next stage."
	fi
done

PKG=(kpat dragon okular krdc kwrite konsole kitty akgregator kmail kmines kmouth kmahjongg kolourpaint spectacle kamoso)
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

echo "###################################################"
echo "###\\\\....  Asyx Desktop Configuration  ....///###"
echo "###################################################"
echo -e "Script is currently running as: $USER.\n Would you like to proceed with this account? Enter y/n\n"
read -n 1 OPTION

####################################
#### Configure Global Variables ####
####################################

### Select USERNAME variable

if [ $OPTION = 'y' ]; then
	USERNAME="$USER"
	echo "\nContinuing desktop configuration based on user: $USERNAME"
elif [ $OPTION = 'n' ]; then
	echo -e "\nInput the desired username:\n"
	read USERNAME
	echo -e "\nYou have entered user: $USERNAME\n"
else
	echo -e "\nInvalid option selected. Exiting script..."
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

### Select desired hostname

echo -e "Select the desired computer hostname\n"
read -n HOSTNAME
echo -e "\nYou have entered $HOSTNAME"

stage_2 ###--- Run Stage 2!
