import anime from 'c/anime';

/**
 * Note the use of function.prototype.call() to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const animationHelper = {

    animateSection(el, eleSectionArrow, type) {
        this._isAccordionProcessing = true;
        let _self = this;
        if (type == "open") {
            el.classList.add("slds-show");
            el.style.height = 'auto';
            let height = el.clientHeight;
            el.style.height = 0;
            anime({
                targets: eleSectionArrow,
                rotate: "0deg",
                duration: 300,
                easing: "linear"
            })
            anime({
                targets: el,
                height: [0, height],
                duration: 700,
                easing: 'easeOutExpo',
                complete: function () {
                    el.style.height = 'auto';
                    _self._isAccordionProcessing = false;
                }
            })
        } else {
            anime({
                targets: eleSectionArrow,
                rotate: "-90deg",
                duration: 300,
                easing: "linear"
            })
            anime({
                targets: el,
                height: 0,
                duration: 700,
                easing: 'easeOutExpo',
                complete: function () {
                    _self._isAccordionProcessing = false;
                }
            })
        }
    }
}