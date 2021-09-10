#pragma once

#include "PluginBase/PDBaseTypes.hpp"

#include <QtPlugin>

#define PDPlugin_IID "plugin.pd.mooody.me"

class PDPluginInterface
{
  public:
    virtual PDPluginId PluginId() const = 0;
    virtual QString QmlImportPath() const = 0;
};

QT_BEGIN_NAMESPACE
Q_DECLARE_INTERFACE(PDPluginInterface, PDPlugin_IID)
QT_END_NAMESPACE
