import anime from 'c/anime';

/**
 * Note the use of function.prototype.call() to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const animationHelper = {

    animateSection(el, eleSectionArrow, type,duration) {
        let totalArrowDuration = 150;
        if(duration) {
            totalArrowDuration = duration;
        }
        this._isAccordionProcessing = true;
        let _self = this;
        if (type == "open") {
            el.classList.add("slds-show");
            el.style.height = 'auto';
            let height = el.clientHeight;
            el.style.height = 0;
            anime({
                targets: eleSectionArrow,
                rotate: "+90deg",
                duration: totalArrowDuration,
                easing: "linear"
            })
            anime({
                targets: el,
                height: [0, height],
                duration: 150,
                easing: 'easeOutExpo',
                complete: function () {
                    el.style.height = 'auto';
                    _self._isAccordionProcessing = false;
                }
            })
        } else {
            anime({
                targets: eleSectionArrow,
                rotate: "0deg",
                duration: totalArrowDuration,
                easing: "linear"
            })
            anime({
                targets: el,
                height: 0,
                duration: 150,
                easing: 'easeOutExpo',
                complete: function () {
                    _self._isAccordionProcessing = false;
                }
            })
        }
    }
}