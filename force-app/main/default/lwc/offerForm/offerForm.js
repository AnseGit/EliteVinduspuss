import { LightningElement} from 'lwc';

export default class OfferForm extends LightningElement {
    _inputVariables = [];

    /**
     * Get flow input variables
     */
    get inputVariables() {
      return this._inputVariables;
    }

}