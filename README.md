# Order & Payment Desk

Advance, invoicing and dispatch tracking for three companies (Sunshine Industries, Sunshine Cosmetics Pvt Ltd, Dyana International), all in the same format:

1. Client / Brand
2. Products
3. Advance (received and pending)
4. Daily Invoicing
5. Pending Dispatch

It is a single static page (`index.html`). There is no server.

## Where the data lives

Data is saved in the browser you use, on that device only. To move it to another browser or device, use **Backup** (downloads a JSON file) and **Restore** (loads it again). Take a backup regularly. Clearing browser data erases what is saved.

## How the numbers work

- Advance required = PO quantity x final cost x advance % (set on the product).
- Invoice: non-GST = quantity x final cost; GST = 18% on (non-GST + freight/development charges).
- Advance adjusted = invoice quantity x final cost x advance %, never more than the advance actually received for that PO and product.
- Net receivable = invoice total - advance adjusted. Due date = invoice date + the product's payment terms.
- Pending dispatch = PO quantity - dispatched quantity.
