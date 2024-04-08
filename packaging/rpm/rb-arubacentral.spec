%global __brp_mangle_shebangs %{nil}

Name:     rb-arubacentral
Version:  %{__version}
Release:  %{__release}%{?dist}
BuildArch: noarch
Summary: redborder arubacentral

License:  GNU AGPLv3
URL:  https://github.com/redBorder/rb-arubacentral
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/usr/lib/%{name}
install -D -m 644 resources/systemd/%{name}.service %{buildroot}/usr/lib/systemd/system/%{name}.service
mkdir -p %{buildroot}/var/%{name}/bin/api
mkdir -p %{buildroot}/var/%{name}/bin/helpers
mkdir -p %{buildroot}/var/%{name}/bin/kafka
install -D -m 755 bin/rb_arubacentral.rb %{buildroot}/var/rb-arubacentral/bin/rb_arubacentral.rb
install -D -m 755 bin/api/aruba_client.rb %{buildroot}/var/rb-arubacentral/bin/api/aruba_client.rb
install -D -m 755 bin/helpers/aruba_builder.rb %{buildroot}/var/rb-arubacentral/bin/helpers/aruba_builder.rb
install -D -m 755 bin/helpers/aruba_config.rb %{buildroot}/var/rb-arubacentral/bin/helpers/aruba_config.rb
install -D -m 755 bin/helpers/aruba_logger.rb %{buildroot}/var/rb-arubacentral/bin/helpers/aruba_logger.rb
install -D -m 755 bin/helpers/aruba_math.rb %{buildroot}/var/rb-arubacentral/bin/helpers/aruba_math.rb
install -D -m 755 bin/helpers/aruba_oauth.rb %{buildroot}/var/rb-arubacentral/bin/helpers/aruba_oauth.rb
install -D -m 755 bin/kafka/producer.rb %{buildroot}/var/rb-arubacentral/bin/kafka/producer.rb

%clean
rm -rf %{buildroot}

%pre
getent group %{name} >/dev/null || groupadd -r %{name}
getent passwd %{name} >/dev/null || \
    useradd -r -g %{name} -d / -s /sbin/nologin \
    -c "User of %{name} service" %{name}
exit 0

%post
systemctl daemon-reload || :

%postun
systemctl daemon-reload || :

%files
%defattr(755,%{name},root)
/var/rb-arubacentral/bin/
/var/rb-arubacentral/bin/api
/var/rb-arubacentral/bin/helpers
/var/rb-arubacentral/bin/kafka
/var/rb-arubacentral/bin/rb_arubacentral.rb
%defattr(644,root,root)
/var/rb-arubacentral/bin/api/aruba_client.rb
/var/rb-arubacentral/bin/helpers/aruba_builder.rb
/var/rb-arubacentral/bin/helpers/aruba_config.rb
/var/rb-arubacentral/bin/helpers/aruba_logger.rb
/var/rb-arubacentral/bin/helpers/aruba_math.rb
/var/rb-arubacentral/bin/helpers/aruba_oauth.rb
/var/rb-arubacentral/bin/kafka/producer.rb
/usr/lib/systemd/system/%{name}.service

%changelog
* Mon Jan 15 2024 David Vanhoucke <dvanhoucke@redborder.com> - 0.0.1
- first spec version
