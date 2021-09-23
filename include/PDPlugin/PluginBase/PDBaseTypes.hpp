#pragma once

#include <QDebug>
#include <QMap>
#include <QString>
#include <QVariant>

// clang-format off
#define DeclareSafeID(type)                                                                                                                                              \
namespace PD::Plugin::Types::_safetypes{ class __##type; }                                                                                                           \
    typedef PD::Plugin::Types::PDId_t<PD::Plugin::Types::_safetypes::__##type> type;                                                                                      \
    Q_DECLARE_METATYPE(type)
// clang-format on

namespace PD::Plugin::Types
{
    template<typename T>
    struct PDId_t
    {
        PDId_t() : m_id(u"null"_qs){};
        explicit PDId_t(const QString &id) : m_id(id){};
        ~PDId_t() = default;
        // clang-format off
        inline bool operator==(const PDId_t<T> &rhs) const { return m_id == rhs.m_id; }
        inline bool operator!=(const PDId_t<T> &rhs) const { return m_id != rhs.m_id; }
        inline const QString toString() const { return m_id; }
        inline bool isNull() const { return m_id == u"null"_qs; }
        // clang-format on

      private:
        QString m_id;
    };

    template<typename T>
    uint qHash(const PDId_t<T> &id)
    {
        return qHash(id.toString());
    }

    template<typename T>
    QDebug operator<<(QDebug debug, const PDId_t<T> &c)
    {
        QDebugStateSaver saver(debug);
        debug.nospace() << '[' << c.toString() << ']';
        return debug;
    }

    typedef std::tuple<QString, QString, QVariant> PDPropertyDescriptor;

    struct PDPluginQmlTypeInfo
    {
        QString Description;
        QString QmlFilePath;
        QString IconPath;
        QList<PDPropertyDescriptor> Properties;
    };

} // namespace PD::Plugin::Types

DeclareSafeID(PDPluginId);

Q_DECLARE_METATYPE(PD::Plugin::Types::PDPropertyDescriptor)
Q_DECLARE_METATYPE(PD::Plugin::Types::PDPluginQmlTypeInfo)
