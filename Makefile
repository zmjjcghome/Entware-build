#
# Copyright (C) 2019 OpenWrt.org
#
# KFERMercer <KFER.Mercer@gmail.com>
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=baidupcs-web
PKG_VERSION:=3.7.3
PKG_RELEASE:=3

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/Erope/BaiduPCS-Go.git
PKG_SOURCE_VERSION:=b2f5436699d1acd6dc3d90f2066bf1e36c373cd5
PKG_MIRROR_HASH:=815410a7c348c82eea638f6d34fd4dfab59286e16b172c434ff0008de24676dc

PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

PKG_CONFIG_DEPENDS:= \
	CONFIG_BAIDUPCS_WEB_COMPRESS_GOPROXY \
	CONFIG_BAIDUPCS_WEB_COMPRESS_UPX

PKG_BUILD_DEPENDS:=golang/host
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

GO_PKG:=github.com/Erope/BaiduPCS-Go
GO_PKG_LDFLAGS:=-s -w
GO_PKG_LDFLAGS_X:=main.Version=v$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/golang.mk

ifeq ($(BUILD_VARIANT),nohf)
GOARM=GOARM=5
endif

define Package/$(PKG_NAME)
	SECTION:=net
	CATEGORY:=Network
	TITLE:=BaiduPCS-Web is a web controller for BaiduPCS-Go
	URL:=https://github.com/Erope/BaiduPCS-Go
	DEPENDS:=$(GO_ARCH_DEPENDS)
endef

define Package/$(PKG_NAME)/description
BaiduPCS-Web is a web controller for BaiduPCS-Go
endef

define Package/$(PKG_NAME)/config
config BAIDUPCS_WEB_COMPRESS_GOPROXY
	bool "Compiling with GOPROXY proxy"
	default n

config BAIDUPCS_WEB_COMPRESS_UPX
	bool "Compress executable files with UPX"
	default y
endef

ifeq ($(CONFIG_BAIDUPCS_WEB_COMPRESS_GOPROXY),y)
	export GO111MODULE=on
	export GOPROXY=https://goproxy.baidu.com
endif

define Build/Compile
( \
  CGO_ENABLED=0 GO111MODULE=on GOOS=linux GOARCH=$(GOARCH) $(GOARM) go get -v github.com/GeertJohan/go.rice/rice/... ; \
  cd $(PKG_BUILD_DIR)/internal/pcsweb ; \
  "$(PKG_BUILD_DIR)/bin/rice" embed-go ; \
)
	$(call GoPackage/Build/Compile)
ifeq ($(CONFIG_BAIDUPCS_WEB_COMPRESS_UPX),y)
	$(STAGING_DIR_HOST)/bin/upx --lzma --best $(GO_PKG_BUILD_BIN_DIR)/BaiduPCS-Go
endif
endef

define Package/$(PKG_NAME)/install
	$(call GoPackage/Package/Install/Bin,$(PKG_INSTALL_DIR))
	$(INSTALL_DIR) $(1)/opt/bin
	$(INSTALL_BIN) $(GO_PKG_BUILD_BIN_DIR)/BaiduPCS-Go $(1)/opt/bin/$(PKG_NAME)
endef

$(eval $(call GoBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
