import { useCallback } from 'react'
import { useDataStore } from '../store/useDataStore'
import { useUIStore } from '../store/useUIStore'

// Soft-deletes a transaction and offers Undo in the toast.
export function useDeleteWithUndo() {
  return useCallback((tx) => {
    const { deleteTransaction, restoreTransaction } = useDataStore.getState()
    deleteTransaction(tx.id)
    useUIStore.getState().showToast('Entry deleted', {
      action: { label: 'Undo', onClick: () => restoreTransaction(tx.id) },
    })
  }, [])
}
