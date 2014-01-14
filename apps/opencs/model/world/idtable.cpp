
#include "idtable.hpp"

#include "collectionbase.hpp"
#include "columnbase.hpp"

CSMWorld::IdTable::IdTable (CollectionBase *idCollection, Reordering reordering)
: mIdCollection (idCollection), mReordering (reordering)
{}

CSMWorld::IdTable::~IdTable()
{}

int CSMWorld::IdTable::rowCount (const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;

    return mIdCollection->getSize();
}

int CSMWorld::IdTable::columnCount (const QModelIndex & parent) const
{
    if (parent.isValid())
        return 0;

    return mIdCollection->getColumns();
}

QVariant CSMWorld::IdTable::data  (const QModelIndex & index, int role) const
{
    if (role!=Qt::DisplayRole && role!=Qt::EditRole)
        return QVariant();

    if (role==Qt::EditRole && !mIdCollection->getColumn (index.column()).isEditable())
        return QVariant();

    return mIdCollection->getData (index.row(), index.column());
}

QVariant CSMWorld::IdTable::headerData (int section, Qt::Orientation orientation, int role) const
{
    if (orientation==Qt::Vertical)
        return QVariant();

    if (role==Qt::DisplayRole)
        return tr (mIdCollection->getColumn (section).getTitle().c_str());

    if (role==ColumnBase::Role_Flags)
        return mIdCollection->getColumn (section).mFlags;

    if (role==ColumnBase::Role_Display)
        return mIdCollection->getColumn (section).mDisplayType;

    return QVariant();
}

bool CSMWorld::IdTable::setData ( const QModelIndex &index, const QVariant &value, int role)
{
    if (mIdCollection->getColumn (index.column()).isEditable() && role==Qt::EditRole)
    {
        mIdCollection->setData (index.row(), index.column(), value);

        emit dataChanged (CSMWorld::IdTable::index (index.row(), 0),
            CSMWorld::IdTable::index (index.row(), mIdCollection->getColumns()-1));

        return true;
    }

    return false;
}

Qt::ItemFlags CSMWorld::IdTable::flags (const QModelIndex & index) const
{
    Qt::ItemFlags flags = Qt::ItemIsSelectable | Qt::ItemIsEnabled;

    if (mIdCollection->getColumn (index.column()).isUserEditable())
        flags |= Qt::ItemIsEditable;

    return flags;
}

bool CSMWorld::IdTable::removeRows (int row, int count, const QModelIndex& parent)
{
    if (parent.isValid())
        return false;

    beginRemoveRows (parent, row, row+count-1);

    mIdCollection->removeRows (row, count);

    endRemoveRows();

    return true;
}

QModelIndex CSMWorld::IdTable::index (int row, int column, const QModelIndex& parent) const
{
    if (parent.isValid())
        return QModelIndex();

    if (row<0 || row>=mIdCollection->getSize())
        return QModelIndex();

    if (column<0 || column>=mIdCollection->getColumns())
        return QModelIndex();

    return createIndex (row, column);
}

QModelIndex CSMWorld::IdTable::parent (const QModelIndex& index) const
{
    return QModelIndex();
}

void CSMWorld::IdTable::addRecord (const std::string& id, UniversalId::Type type)
{
    int index = mIdCollection->getAppendIndex (id, type);

    beginInsertRows (QModelIndex(), index, index);

    mIdCollection->appendBlankRecord (id, type);

    endInsertRows();
}

QModelIndex CSMWorld::IdTable::getModelIndex (const std::string& id, int column) const
{
    return index (mIdCollection->getIndex (id), column);
}

void CSMWorld::IdTable::setRecord (const std::string& id, const RecordBase& record)
{
    int index = mIdCollection->searchId (id);

    if (index==-1)
    {
        int index = mIdCollection->getAppendIndex (id);

        beginInsertRows (QModelIndex(), index, index);

        mIdCollection->appendRecord (record);

        endInsertRows();
    }
    else
    {
        mIdCollection->replace (index, record);
        emit dataChanged (CSMWorld::IdTable::index (index, 0),
            CSMWorld::IdTable::index (index, mIdCollection->getColumns()-1));
    }
}

const CSMWorld::RecordBase& CSMWorld::IdTable::getRecord (const std::string& id) const
{
    return mIdCollection->getRecord (id);
}

int CSMWorld::IdTable::searchColumnIndex (Columns::ColumnId id) const
{
    return mIdCollection->searchColumnIndex (id);
}

int CSMWorld::IdTable::findColumnIndex (Columns::ColumnId id) const
{
    return mIdCollection->findColumnIndex (id);
}

void CSMWorld::IdTable::reorderRows (int baseIndex, const std::vector<int>& newOrder)
{
    if (!newOrder.empty())
        if (mIdCollection->reorderRows (baseIndex, newOrder))
            emit dataChanged (index (baseIndex, 0),
                index (baseIndex+newOrder.size()-1, mIdCollection->getColumns()-1));
}

CSMWorld::IdTable::Reordering CSMWorld::IdTable::getReordering() const
{
    return mReordering;
}