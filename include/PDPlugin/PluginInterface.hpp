#pragma once

#include "PluginBase/PDBaseTypes.hpp"

#include <QStringList>
#include <QtPlugin>

#define PDPlugin_IID "plugin.pd.mooody.me"

#ifndef PDPLUGIN_QML_URI
#define PDPLUGIN_QML_URI "(null)"
#endif

#ifndef PDPLUGIN_QML_IMPORT_PATH
#define PDPLUGIN_QML_IMPORT_PATH "/(null)/"
#endif

namespace PD::Plugin
{
    class PDPluginInterface
    {
      protected:
        PDPluginInterface(){};

      public:
        virtual ~PDPluginInterface(){};
        virtual void RegisterQMLTypes() = 0;
        virtual QMap<QString, Types::PDPluginQmlTypeInfo> QmlComponentTypes() = 0;

        virtual PDPluginId PluginId() const
        {
            return PDPluginId{ QStringLiteral(PDPLUGIN_QML_URI) };
        }

        virtual QStringList QmlImportPaths() const
        {
            return {};
        }

        virtual const QString QmlInternalImportPath() const final
        {
            return QStringLiteral(PDPLUGIN_QML_IMPORT_PATH);
        }

        virtual const char *QmlInternalModuleName() const final
        {
            return PDPLUGIN_QML_URI;
        }
    };
} // namespace PD::Plugin

QT_BEGIN_NAMESPACE
Q_DECLARE_INTERFACE(PD::Plugin::PDPluginInterface, PDPlugin_IID)
QT_END_NAMESPACE
