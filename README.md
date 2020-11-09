# Salesforce Component Package Manager

*AKA Steam for Salesforce*

![Main App Screenshot](/readme-extras/mainappscreenshot.png)

Ok, lets be real, this is nowhere near as incredible as [Steam](https://store.steampowered.com/), BUT! It does try and solve some core issues that Salesforce Solution Engineers Deal with.

- Allows you to auto-discover what is installed on your org.
- Gives you a single interface to install small demo components from code to Salesforce AppExchange apps.
- Tracks and notifies you when Updates are available (SFDX Projects Only)
- Allows you to add new components to your org from a source code repository (Currently Github Only).
- Provides the capabilities for Post-Install Activies to be performed (Coming Soon!)

*NOTE: This Package depends upon a [Deploy to SFDX Project Fork](https://github.com/davidlarrimore/deploy-to-sfdx) that manages the installation of source code to the org*

## Installation

[CLICK HERE TO INSTALL](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3h000004Rc0wAAC) (v0.1.0-1)

## Post Install Tasks

Until the Post-Install Activities feature is implemented, the "Demo_Component_Manager" Permission set must be added to your administrative users.

## Navigating the App

### Main App Page

![Main App Screenshot](/readme-extras/mainappscreenshot.png)

The Main App Page allows you to navigate the available components, installed components, and add new components.

### Component Page

![Main App Screenshot](/readme-extras/componentpagescreenshot.png)

The Component Page allows you to install the package, see any dependencies, and other package information.

## Want to Contribute

If you want to contribute to this project, please feel free to fork, or contact [davidlarrimore@gmail.com](mailto:davidlarrimore@gmail.com)
