import React from 'react'
import Button from '../ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { DialogViewKey } from '@/hooks/use-dialog-factory';
import { truncateAddress } from '@/lib/utils';

type Props = {
  setView: (viewKey: DialogViewKey) => void;
}

const PLACEHOLDER_BODS = [{
  id: "1",
  address: "0xb03258C4FA44e6e3C5Eb5A0624914D3b526491B1"
}]

function ChooseBODDialog({ setView }: Props) {
  return (
    <div>
      <div>
        <p>{`You can reuse any one of your existing BODs or create a new one.`}</p>
      </div>

      <div className='space-y-2'>
        <div className='space-y-1'>
          <label>Select a Bitcoin Pod (BOD)</label>
          <Select onValueChange={(value) => {
            if (value === 'create') {
              return;
            }

            setView("deployBOD");
          }}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value='create'>Create a new Bitcoin Pod</SelectItem>
              {PLACEHOLDER_BODS.map((bod) => (
                <SelectItem key={bod.id} value={bod.address}>{truncateAddress(bod.address)}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <Button>Create a Bitcoin Pod</Button>
      </div>
    </div>
  )
}

export default ChooseBODDialog
