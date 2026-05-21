#!/bin/bash

########################################
#####---    Global Variables    ---#####
########################################
USERNAME=asyx

########################################
#####---  Global Dependencies   ---#####
########################################

DEVPKG=(git make)
echo -e "Installing essential dependencies"
for pkg in "${DEVPKG[@]}"; do
    if rpm -q "$pkg" 2>/dev/null; then
        echo -e "$pkg is already installed"
    else
        dnf install -y "$pkg"
    fi
done

#######################################
#####--- ML4Q/ Hyprland install---#####
#######################################

##################
##.. Stage #1 ..##
##################

echo -e "Running Desktop config Stage 1\n Checking if Hyprland is instaled"
if rpm -q hyprland 2>/dev/null; then
	echo -e "ML4W OS/ Hyprland is already installed\n Proceeding with next stage."
else
	bash <(curl -s https://ml4w.com/os/stable)
fi

#######################################
#####---       Debloater       ---#####
#######################################

##################
##.. Stage #2 ..##
##################

echo -e "Running Desktop config Stage 2\n Detecting unnecessary packages"

BLOATPKG=(kpat dragon okular krdc kwrite konsole kitty akgregator kmail kmines kmouth kolourpaint spectacle kamoso)
for pkg in "${BLOATPKG[@]}"; do
	if rpm -q "$pkg" 2>/dev/null; then
		echo -e "Uninstalling $pkg"
		dnf -y remove "$pkg"
	else
		echo -e "No packages to remove.\n Proceeding with next stage."
	fi
done  

#######################################
#####---     Customization     ---#####
#######################################

##################
##.. Stage #3 ..##
##################
echo -e "Running Desktop config Stage 3\n Installing new packages."

echo -e "Enabling additional repositories."
echo -e "Enabling Alacritty repository."
dnf copr enable pschyska/alacritty																																	                            
NEWPKG=(vscode alacritty)

echo -e "Installing packages through RPM...\n"
for pkg in "${NEWPKG[@]}"; do
	if ! rpm -q "$pkg" 2>/dev/null; then
		echo -e "Installing $pkg"
		dnf -y install "$pkg"
	else
		echo -e "Package" $(rpm -q "$pkg") "is already installed."
	fi
done 

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
    mv zen /opt/zen/ # "Install"
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
