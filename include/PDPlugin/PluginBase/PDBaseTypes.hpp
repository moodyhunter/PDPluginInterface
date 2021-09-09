#pragma once

#include <QDebug>
#include <QString>

namespace PD::Plugin::Types
{
    // clang-format off
    template<typename T>
    struct PDIdT
    {
        PDIdT() : m_id(u"null"_qs){};
        explicit PDIdT(const QString &id) : m_id(id){};
        ~PDIdT() = default;
        inline bool operator==(const PDIdT<T> &rhs) const { return m_id == rhs.m_id; }
        inline bool operator!=(const PDIdT<T> &rhs) const { return m_id != rhs.m_id; }
        inline const QString toString() const { return m_id; }
        inline bool isNull() const { return m_id == u"null"_qs; }

      private:
        QString m_id;
    };
    // clang-format on

    template<typename T>
    uint qHash(const PDIdT<T> &id)
    {
        return qHash(id.toString());
    }

    template<typename T>
    QDebug operator<<(QDebug debug, const PDIdT<T> &c)
    {
        QDebugStateSaver saver(debug);
        debug.nospace() << QMetaType::fromType<decltype(c)>().name() << '[' << c.toString() << ']';
        return debug;
    }
} // namespace PD::Plugin::Types

// clang-format off
#define DeclareSafeID(type)                                                                                                                                              \
    namespace PD::Plugin::Types::_safetypes{ class __##type; }                                                                                                           \
    typedef PD::Plugin::Types::PDIdT<PD::Plugin::Types::_safetypes::__##type> type;                                                                                      \
    Q_DECLARE_METATYPE(type)
// clang-format on

DeclareSafeID(PDPluginId);
