import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import uploadFile from "@salesforce/apex/FileUploaderClass.uploadFile";
import {
  FlowAttributeChangeEvent,
  FlowNavigationNextEvent
} from "lightning/flowSupport";
import { deleteRecord } from "lightning/uiRecordApi";

export default class CustomFileUploader extends LightningElement {
  @api recordId;
  @api supportedFileTypes;
  @api contentDocumentIds;
  @api buttonLabel = "Upload";
  @api navigateNextOnUpload = false;
  @api showPillContainer = false;
  @track files = [];
  _contentDocumentIds = [];

  fileData;
  async handleReadFile(event) {
    await this.readFile(event);
    if (this.fileData) {
      await this.handleUploadFile();
    }
  }

  readFile(event) {
    return new Promise((resolve, reject) => {
      const file = event.target.files[0];
      if (!file) {
        console.error("No file selected");
        reject("No file selected");
        return;
      }

      const reader = new FileReader();
      reader.onload = () => {
        const base64 = reader.result.split(",")[1];
        this.fileData = {
          filename: file.name,
          base64: base64,
          recordId: this.recordId
        };
        console.log(this.fileData);
        resolve(); // Resolve the promise when done
      };
      reader.onerror = (error) => {
        console.error("Error reading file:", error);
        reject(error); // Reject on error
      };
      reader.readAsDataURL(file);
    });
  }

  async handleUploadFile() {
    console.log("handleUploadFile");
    const { base64, filename, recordId } = this.fileData;
    uploadFile({ base64, filename, recordId })
      .then((result) => {
        this.fileData = null;
        console.debug("result apx", result);
        let title = `${filename} uploaded successfully!!`;
        this.toast(title);
        this.files.push({ fileName: filename, recordId: result });
        this._contentDocumentIds.push(result);
      })
      .then(() => {
        this.setFlowOutput();
      })
      .finally(() => {
        if (this.navigateNextOnUpload) {
          const navigateNextEvent = new FlowNavigationNextEvent();
          this.dispatchEvent(navigateNextEvent);
        }
        console.log("this.files", this.files);
      });
  }

  toast(title) {
    const toastEvent = new ShowToastEvent({
      title,
      variant: "success"
    });
    this.dispatchEvent(toastEvent);
  }

  setFlowOutput() {
    console.debug("Files uploaded", JSON.stringify(this._contentDocumentIds));
    const attributeChangeEvent = new FlowAttributeChangeEvent(
      "contentDocumentIds",
      this._contentDocumentIds
    );
    this.dispatchEvent(attributeChangeEvent);
  }

  handleRemove(event) {
    console.log("handleRemove", event.target.dataset);
    let recordId = event.target.dataset.recordId;
    if (recordId) {
      deleteRecord(recordId);
      this._contentDocumentIds = this._contentDocumentIds.filter(
        (id) => id !== recordId
      );
      this.files = this.files.filter((file) => file.recordId !== recordId);
    }
  }
}