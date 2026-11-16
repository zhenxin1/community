# 需求实现与验证追溯矩阵

所有Java源码相对PetAdoptionCommunity/src/main/java/com/example/petadoptioncommunity。测试名称对应tests/integration.py和evidence/integration-results.json中的实际检查项。页面路由见vue1/src/router.js。

| FR | 故事 | ADR | 实现 | 验证 |
|---|---|---|---|---|
|FR-01|1.1|001/002|identity/IdentityService.java|unknown registration fields cannot elevate / wrong login generic rejection|
|FR-02|1.1/1.2|002/003|identity/IdentityService.java|frozen old session revoked / password rotation revokes all sessions|
|FR-03|1.2|002|identity/IdentityService.java|profile plain text stored / stale profile version rejected|
|FR-04|1.4|002/003|administration/StateCommandService.java|freeze repeated command has one result / unfreeze does not restore old session|
|FR-05|1.3/1.5|003|notification/NotificationService.java + administration/StateCommandService.java|message idempotency / foreign notification rejected / read keeps first timestamp|
|FR-06|2.1|009|adoption/AdoptionService.java + media/MediaService.java|visitor contacts absent；补充媒体测试见quality-results.json|
|FR-07|2.2|004|adoption/AdoptionService.java|浏览器搜索和详情；quality-results.json|
|FR-08|2.2|008|adoption/AdoptionService.java|logged in available contact visible / handover other applicant contacts removed|
|FR-09|2.3|004|adoption/AdoptionService.java|self application rejected / parallel same applicant one active application|
|FR-10|2.3/2.4|004|adoption/AdoptionService.java|parallel selection one winner / unrelated confirmation rejected|
|FR-11|2.5|004|adoption/AdoptionService.java|single party repeat remains selected / double confirmation repeated remains successful|
|FR-12|2.6|004|adoption/AdoptionService.java|failure restores available / old successful confirmation cannot affect new handover|
|FR-13|3.1|007/009|shop/ShopService.java|浏览器分类详情；quality-results.json|
|FR-14|4.1|005|shop/ShopService.java|USER cannot create product；quantity与version边界|
|FR-15|3.2|005|shop/ShopService.java|fractional cart quantity rejected；浏览器加购|
|FR-16|3.3|006|shop/ShopService.java|foreign address modification rejected / address changed quote requires reconfirmation|
|FR-17|3.3|006|shop/Pricing.java|PricingTest与300 threshold with 20 percent discount|
|FR-18|3.4|006|shop/ShopService.java|order creation same key one order / address changed quote requires reconfirmation|
|FR-19|3.5|003/005|shop/ShopService.java|last stock one payment winner / multi-product stock failure leaves other stock|
|FR-20|3.6|005/008|shop/ShopService.java|order cannot read across user / payment cancel competition one effective state|
|FR-21|3.7/4.2|005|shop/ShopService.java|unpaid cannot ship / shipment receipt idempotent；浏览器发货收货|

各领域遵守Controller→Service→Mapper分层。账号服务提供身份和会话能力，领养服务管理申请与交接状态，商城服务管理报价、库存与履约；涉及本人资源的操作均在Service层检查归属。
