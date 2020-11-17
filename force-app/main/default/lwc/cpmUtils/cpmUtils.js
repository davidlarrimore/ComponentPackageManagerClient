import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class cpmUtils {
	static showToast = (firingComponent, toastTitle, toastBody, variant) => {
		const evt = new ShowToastEvent({
			title: toastTitle,
			message: toastBody,
			variant: variant
		});
		firingComponent.dispatchEvent(evt);
	};

	static showModal = (firingComponent, header, content) => {
		const evt = new CustomEvent("showmodal", {
			detail: {
				header,
				content
			},
			bubbles: true,
			composed: true
		});
		firingComponent.dispatchEvent(evt);
	};
}