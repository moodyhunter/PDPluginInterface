#pragma once

#include "PluginBase/PDBaseTypes.hpp"

#include <QQmlEngineExtensionPlugin>
#include <QtPlugin>

#define PDPlugin_IID "plugin.pd.mooody.me"

class PDPluginInterface : public QQmlEngineExtensionInterface
{
  public:
    virtual PDPluginId PluginId() const = 0;
};

QT_BEGIN_NAMESPACE
Q_DECLARE_INTERFACE(PDPluginInterface, PDPlugin_IID)
QT_END_NAMESPACE

class PDPlugin
    : public QObject
    , public PDPluginInterface
{
    Q_OBJECT
    Q_INTERFACES(PDPluginInterface)
    Q_INTERFACES(QQmlEngineExtensionInterface)

  private:
    Q_DISABLE_COPY_MOVE(PDPlugin)
};
