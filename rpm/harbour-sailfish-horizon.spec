Name:       harbour-sailfish-horizon

Summary:    Dedicated Enterprise Outlook Web Client
Version:    1.0.0
Release:    1
License:    GPLv3
URL:        https://github.com/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   sailfish-components-webview-qt5
Requires:   sailfish-components-webview-qt5-popups
Requires:   nemo-qml-plugin-notifications
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5DBus)
BuildRequires:  desktop-file-utils

%description
A standalone, isolated web container for enterprise Microsoft Outlook 365,
running independently from the default Sailfish browser with native DBus notifications,
modern tall display optimization, and background sync.

%prep
%setup -q -n %{name}-%{version}

%build
%qmake5 
%make_build

%install
%qmake5_install
desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/%{name}.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/icons/hicolor/scalable/apps/%{name}.svg
%{_prefix}/lib/systemd/user/%{name}.service
%{_prefix}/lib/systemd/user/%{name}.timer
