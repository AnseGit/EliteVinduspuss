import { LightningElement, api, wire } from 'lwc';
//import preview from './preview.html';
import flow from './Flow.html';
import { CurrentPageReference } from 'lightning/navigation';

export default class /*UserPreferenceWrapper */ OfferForm extends LightningElement {
  //  _individualId;
  //  _hashId;
    showFlow = true;
    _isInEditorMode = false;
    _inputVariables = [];

    render() {
        return this._isInEditorMode ? preview : flow; 
    }
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
           this._isInEditorMode = currentPageReference.state?.view === 'editor';
       }
    }

/*
    @api
    get individualId() {
        return this._individualId;
    }
    set individualId(value) {
        this._individualId = value;
        if (!!this._individualId) {
            this._inputVariables.push({
                name: 'var_T_IndividualId',
                type: 'String',
                value: this._individualId
            });
            this.showFlow = true;
        }
    }

    @api
    get hashId() {
        return this._hashId;
    }
    set hashId(value) {
        this._hashId = value;
        if (!!this._hashId) {
            this._inputVariables.push({
                name: 'var_T_HashId',
                type: 'String',
                value: this._hashId
            });
            this.showFlow = true;
        }
    } */

    /**
     * Get flow input variables
     */
    get inputVariables() {
      return this._inputVariables;
    }

}