using Microsoft.AspNetCore.Mvc;

namespace EduHub.Web.Controllers;

public class AccountController : Controller
{
    // GET: /Account/ForgotPassword
    [HttpGet]
    public IActionResult ForgotPassword()
    {
        return View();
    }
}
